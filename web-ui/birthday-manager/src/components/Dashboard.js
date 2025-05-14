import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../services/api';
import { format, differenceInDays } from 'date-fns';
import Header from './Header';

const Dashboard = () => {
  const [birthdays, setBirthdays] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchBirthdays = async () => {
      try {
        setLoading(true);
        // Clear any local storage that might be causing issues
        localStorage.removeItem('birthdays');
        
        const data = await api.getBirthdays();
        console.log('Fetched birthdays from API:', data);
        setBirthdays(data);
      } catch (err) {
        console.error('Error fetching birthdays:', err);
        setError('Failed to load birthdays. Please try again later.');
      } finally {
        setLoading(false);
      }
    };

    fetchBirthdays();
  }, []);

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this birthday?')) {
      try {
        await api.deleteBirthday(id);
        // Refresh the list after deletion
        const updatedBirthdays = await api.getBirthdays();
        setBirthdays(updatedBirthdays);
      } catch (err) {
        console.error('Error deleting birthday:', err);
        setError('Failed to delete birthday. Please try again.');
      }
    }
  };

  const getUpcomingBirthdays = () => {
    const today = new Date();
    
    // Filter birthdays happening in the next 30 days
    return birthdays
      .filter(birthday => {
        if (!birthday.birth_date) return false;
        
        try {
          // Parse the date correctly
          const dateParts = birthday.birth_date.split('-');
          if (dateParts.length !== 3) return false;
          
          const birthDate = new Date(
            parseInt(dateParts[0]), 
            parseInt(dateParts[1]) - 1, 
            parseInt(dateParts[2])
          );
          
          // Calculate next birthday
          const nextBirthday = new Date(
            today.getFullYear(),
            birthDate.getMonth(),
            birthDate.getDate()
          );
          
          if (nextBirthday < today) {
            nextBirthday.setFullYear(nextBirthday.getFullYear() + 1);
          }
          
          const daysUntil = differenceInDays(nextBirthday, today);
          return daysUntil <= 30;
        } catch (err) {
          console.error('Error parsing date:', err, birthday.birth_date);
          return false;
        }
      })
      .sort((a, b) => {
        const datePartsA = a.birth_date.split('-');
        const datePartsB = b.birth_date.split('-');
        
        const birthDateA = new Date(
          parseInt(datePartsA[0]), 
          parseInt(datePartsA[1]) - 1, 
          parseInt(datePartsA[2])
        );
        
        const birthDateB = new Date(
          parseInt(datePartsB[0]), 
          parseInt(datePartsB[1]) - 1, 
          parseInt(datePartsB[2])
        );
        
        const nextBirthdayA = new Date(
          today.getFullYear(),
          birthDateA.getMonth(),
          birthDateA.getDate()
        );
        
        const nextBirthdayB = new Date(
          today.getFullYear(),
          birthDateB.getMonth(),
          birthDateB.getDate()
        );
        
        if (nextBirthdayA < today) {
          nextBirthdayA.setFullYear(nextBirthdayA.getFullYear() + 1);
        }
        
        if (nextBirthdayB < today) {
          nextBirthdayB.setFullYear(nextBirthdayB.getFullYear() + 1);
        }
        
        return nextBirthdayA - nextBirthdayB;
      });
  };

  const formatDate = (dateString) => {
    try {
      if (!dateString) return 'No date';
      
      const dateParts = dateString.split('-');
      if (dateParts.length !== 3) return dateString;
      
      const date = new Date(
        parseInt(dateParts[0]), 
        parseInt(dateParts[1]) - 1, 
        parseInt(dateParts[2])
      );
      
      return format(date, 'MMMM d, yyyy');
    } catch (err) {
      console.error('Error formatting date:', err, dateString);
      return dateString;
    }
  };

  const getDaysUntilBirthday = (dateString) => {
    try {
      if (!dateString) return null;
      
      const dateParts = dateString.split('-');
      if (dateParts.length !== 3) return null;
      
      const today = new Date();
      const birthDate = new Date(
        parseInt(dateParts[0]), 
        parseInt(dateParts[1]) - 1, 
        parseInt(dateParts[2])
      );
      
      const nextBirthday = new Date(
        today.getFullYear(),
        birthDate.getMonth(),
        birthDate.getDate()
      );
      
      if (nextBirthday < today) {
        nextBirthday.setFullYear(nextBirthday.getFullYear() + 1);
      }
      
      return differenceInDays(nextBirthday, today);
    } catch (err) {
      console.error('Error calculating days until birthday:', err, dateString);
      return null;
    }
  };

  const getAgeFromBirthdate = (dateString) => {
    try {
      if (!dateString) return null;
      
      const dateParts = dateString.split('-');
      if (dateParts.length !== 3) return null;
      
      const birthDate = new Date(
        parseInt(dateParts[0]), 
        parseInt(dateParts[1]) - 1, 
        parseInt(dateParts[2])
      );
      
      const today = new Date();
      
      let age = today.getFullYear() - birthDate.getFullYear();
      const monthDifference = today.getMonth() - birthDate.getMonth();
      
      if (monthDifference < 0 || (monthDifference === 0 && today.getDate() < birthDate.getDate())) {
        age--;
      }
      
      return age;
    } catch (err) {
      console.error('Error calculating age:', err, dateString);
      return null;
    }
  };

  const upcomingBirthdays = getUpcomingBirthdays();

  if (loading) return <div className="loading">Loading...</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div className="dashboard">
      <Header title="Birthday Dashboard" />
      <p className="subtitle">Keep track of all your important dates</p>
      
      <Link to="/add" className="btn-add">+ Add Birthday</Link>
      
      <h2>Upcoming Birthdays</h2>
      <div className="birthday-cards">
        {upcomingBirthdays.length > 0 ? (
          upcomingBirthdays.map(birthday => (
            <div key={birthday.birthday_id} className="birthday-card upcoming">
              <div className="age-badge">{getAgeFromBirthdate(birthday.birth_date)}</div>
              <h3>{birthday.name}</h3>
              <p>{formatDate(birthday.birth_date)}</p>
              <span className="group-tag">{birthday.group_id}</span>
              <span className="days-badge">{getDaysUntilBirthday(birthday.birth_date)} days</span>
              <div className="actions">
                <Link to={`/edit/${birthday.birthday_id}`} className="edit-btn">
                  Edit
                </Link>
                <button 
                  className="delete-btn"
                  onClick={() => handleDelete(birthday.birthday_id)}
                >
                  Delete
                </button>
              </div>
            </div>
          ))
        ) : (
          <p>No upcoming birthdays in the next 30 days</p>
        )}
      </div>
      
      <h2>All Birthdays</h2>
      <div className="birthday-cards">
        {birthdays.length > 0 ? (
          birthdays.map(birthday => (
            <div key={birthday.birthday_id} className="birthday-card">
              <h3>{birthday.name}</h3>
              <p>{formatDate(birthday.birth_date)}</p>
              <span className="group-tag">{birthday.group_id}</span>
              <div className="actions">
                <Link to={`/edit/${birthday.birthday_id}`} className="edit-btn">
                  Edit
                </Link>
                <button 
                  className="delete-btn"
                  onClick={() => handleDelete(birthday.birthday_id)}
                >
                  Delete
                </button>
              </div>
            </div>
          ))
        ) : (
          <p>No birthdays found. Add your first one!</p>
        )}
      </div>
    </div>
  );
};

export default Dashboard;
