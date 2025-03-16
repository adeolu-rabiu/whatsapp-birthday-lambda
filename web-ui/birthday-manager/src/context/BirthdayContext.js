// src/context/BirthdayContext.js
import React, { createContext, useState, useContext, useEffect } from 'react';

const BirthdayContext = createContext();

export function BirthdayProvider({ children }) {
  // Initialize from localStorage if available
  const [birthdays, setBirthdays] = useState(() => {
    const savedBirthdays = localStorage.getItem('birthdays');
    return savedBirthdays ? JSON.parse(savedBirthdays) : [
      { 
        id: '1', 
        name: 'John Doe', 
        birthDate: '1990-04-15', 
        group: 'Family',
        notes: 'Likes chocolate cake'
      },
      { 
        id: '2', 
        name: 'Jane Smith', 
        birthDate: '1985-07-22', 
        group: 'Friends',
        notes: 'Prefers gifts to parties'
      },
      { 
        id: '3', 
        name: 'Mike Johnson', 
        birthDate: '1992-03-30', 
        group: 'Work',
        notes: 'Allergic to nuts'
      },
      { 
        id: '4', 
        name: 'Sarah Williams', 
        birthDate: '1988-11-05', 
        group: 'Family',
        notes: ''
      }
    ];
  });

  const [groups, setGroups] = useState(() => {
    const savedGroups = localStorage.getItem('groups');
    return savedGroups ? JSON.parse(savedGroups) : [
      { id: '1', name: 'Family' },
      { id: '2', name: 'Friends' },
      { id: '3', name: 'Work' },
      { id: '4', name: 'School' }
    ];
  });

  // Save to localStorage whenever state changes
  useEffect(() => {
    localStorage.setItem('birthdays', JSON.stringify(birthdays));
  }, [birthdays]);

  useEffect(() => {
    localStorage.setItem('groups', JSON.stringify(groups));
  }, [groups]);

  // CRUD operations for birthdays
  const addBirthday = (newBirthday) => {
    const birthdayWithId = { 
      ...newBirthday, 
      id: Date.now().toString() 
    };
    setBirthdays([...birthdays, birthdayWithId]);
    return birthdayWithId;
  };

  const updateBirthday = (id, updatedBirthday) => {
    setBirthdays(
      birthdays.map(birthday => 
        birthday.id === id ? { ...birthday, ...updatedBirthday } : birthday
      )
    );
  };

  const deleteBirthday = (id) => {
    setBirthdays(birthdays.filter(birthday => birthday.id !== id));
  };

  const getBirthday = (id) => {
    return birthdays.find(birthday => birthday.id === id);
  };

  // CRUD operations for groups
  const addGroup = (newGroup) => {
    const groupWithId = {
      ...newGroup,
      id: Date.now().toString()
    };
    setGroups([...groups, groupWithId]);
    return groupWithId;
  };

  const updateGroup = (id, updatedGroup) => {
    setGroups(
      groups.map(group => 
        group.id === id ? { ...group, ...updatedGroup } : group
      )
    );
  };

  const deleteGroup = (id) => {
    // Only delete the group if it's not being used by any birthday
    if (!birthdays.some(birthday => birthday.group === id)) {
      setGroups(groups.filter(group => group.id !== id));
      return true;
    }
    return false;
  };

  // Get birthdays by group
  const getBirthdaysByGroup = (groupId) => {
    return birthdays.filter(birthday => birthday.group === groupId);
  };

  // Get upcoming birthdays (within next 30 days)
  const getUpcomingBirthdays = () => {
    const today = new Date();
    const thirtyDaysLater = new Date(today);
    thirtyDaysLater.setDate(today.getDate() + 30);
    
    return birthdays.filter(birthday => {
      const birthDate = new Date(birthday.birthDate);
      const thisYearBirthday = new Date(
        today.getFullYear(),
        birthDate.getMonth(),
        birthDate.getDate()
      );
      
      // If birthday has already passed this year, check for next year
      if (thisYearBirthday < today) {
        thisYearBirthday.setFullYear(today.getFullYear() + 1);
      }
      
      return thisYearBirthday >= today && thisYearBirthday <= thirtyDaysLater;
    }).sort((a, b) => {
      const dateA = new Date(a.birthDate);
      const dateB = new Date(b.birthDate);
      return dateA.getMonth() - dateB.getMonth() || 
             dateA.getDate() - dateB.getDate();
    });
  };

  // Export and sync functions for future AWS integration
  const exportData = () => {
    return {
      birthdays: birthdays,
      groups: groups
    };
  };

  const importData = (data) => {
    if (data.birthdays) setBirthdays(data.birthdays);
    if (data.groups) setGroups(data.groups);
  };

  // Prepare for future AWS integration
  const syncWithBackend = async () => {
    // This function will be implemented when backend is ready
    // It will handle syncing local state with DynamoDB
    console.log('Syncing with backend...');
    // Future implementation will:
    // 1. Get latest data from DynamoDB
    // 2. Merge with local changes
    // 3. Update DynamoDB with local changes
    // 4. Update local state with merged data
    
    return true; // Return success/failure in the future
  };

  return (
    <BirthdayContext.Provider value={{
      birthdays,
      groups,
      addBirthday,
      updateBirthday,
      deleteBirthday,
      getBirthday,
      addGroup,
      updateGroup,
      deleteGroup,
      getBirthdaysByGroup,
      getUpcomingBirthdays,
      exportData,
      importData,
      syncWithBackend
    }}>
      {children}
    </BirthdayContext.Provider>
  );
}

export function useBirthdays() {
  return useContext(BirthdayContext);
}
