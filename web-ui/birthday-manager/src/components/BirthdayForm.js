import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../services/api';
import Header from './Header';

const BirthdayForm = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEditing = !!id;
  
  const [name, setName] = useState('');
  const [birthDate, setBirthDate] = useState('');
  const [groupId, setGroupId] = useState('');
  const [groups, setGroups] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchGroups = async () => {
      try {
        const data = await api.getWhatsAppGroups();
        setGroups(data);
      } catch (err) {
        console.error('Error fetching groups:', err);
        setError('Failed to load WhatsApp groups');
      }
    };

    fetchGroups();

    // If editing, fetch the birthday details
    if (isEditing) {
      const fetchBirthday = async () => {
        try {
          setLoading(true);
          const birthdays = await api.getBirthdays();
          const birthday = birthdays.find(b => b.birthday_id === id);
          
          if (!birthday) {
            setError('Birthday not found');
            return;
          }
          
          setName(birthday.name || '');
          setBirthDate(birthday.birth_date || '');
          setGroupId(birthday.group_id || '');
        } catch (err) {
          console.error('Error fetching birthday:', err);
          setError('Failed to load birthday details');
        } finally {
          setLoading(false);
        }
      };
      
      fetchBirthday();
    }
  }, [id, isEditing]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!name || !birthDate || !groupId) {
      setError('Please fill in all fields');
      return;
    }
    
    try {
      setLoading(true);
      setError(null);
      
      // Calculate birth_month_day from birthDate (format MM-DD)
      const date = new Date(birthDate);
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const birthMonthDay = `${month}-${day}`;
      
      if (isEditing) {
        await api.updateBirthday(id, {
          name,
          birthDate,
          birthMonthDay,
          group_id: groupId
        });
      } else {
        await api.addBirthday({
          name,
          birthDate,
          birthMonthDay,
          groupId
        });
      }
      
      navigate('/');
    } catch (err) {
      console.error('Error saving birthday:', err);
      setError(`Failed to ${isEditing ? 'update' : 'add'} birthday`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="form-container">
      <Header title={isEditing ? 'Edit Birthday' : 'Add Birthday'} />
      
      {error && <div className="error-message">{error}</div>}
      
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="name">Name</label>
          <input
            type="text"
            id="name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Enter person's name"
            required
          />
        </div>
        
        <div className="form-group">
          <label htmlFor="birthDate">Birth Date</label>
          <input
            type="date"
            id="birthDate"
            value={birthDate}
            onChange={(e) => setBirthDate(e.target.value)}
            required
          />
        </div>
        
        <div className="form-group">
          <label htmlFor="groupId">WhatsApp Group</label>
          <select
            id="groupId"
            value={groupId}
            onChange={(e) => setGroupId(e.target.value)}
            required
          >
            <option value="">Select WhatsApp Group</option>
            {groups.map(group => (
              <option key={group.group_id} value={group.group_id}>
                {group.name}
              </option>
            ))}
          </select>
        </div>
        
        <div className="form-actions">
          <button
            type="button"
            className="btn-cancel"
            onClick={() => navigate('/')}
          >
            Cancel
          </button>
          <button
            type="submit"
            className="btn-primary"
            disabled={loading}
          >
            {loading ? 'Saving...' : (isEditing ? 'Update Birthday' : 'Add Birthday')}
          </button>
        </div>
      </form>
    </div>
  );
};

export default BirthdayForm;
