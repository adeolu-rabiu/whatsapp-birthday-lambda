import React from 'react';

const ClearStorage = () => {
  const handleClearStorage = () => {
    localStorage.clear();
    window.location.reload();
    alert('Local storage cleared! The app will now reload.');
  };

  return (
    <button 
      onClick={handleClearStorage}
      style={{
        position: 'fixed',
        bottom: '10px',
        right: '10px',
        background: '#f44336',
        color: 'white',
        border: 'none',
        padding: '8px 16px',
        borderRadius: '4px',
        cursor: 'pointer',
        zIndex: 1000
      }}
    >
      Clear Local Storage
    </button>
  );
};

export default ClearStorage;
