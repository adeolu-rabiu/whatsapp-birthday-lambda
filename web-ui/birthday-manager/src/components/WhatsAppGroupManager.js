import React, { useState, useEffect } from 'react';
import api from '../services/api';
import Header from './Header';

const WhatsAppGroupManager = () => {
  const [groups, setGroups] = useState([]);
  const [newGroupName, setNewGroupName] = useState('');
  const [newGroupDescription, setNewGroupDescription] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchGroups();
  }, []);

  const fetchGroups = async () => {
    try {
      setLoading(true);
      const data = await api.getWhatsAppGroups();
      setGroups(data);
    } catch (err) {
      console.error('Error fetching WhatsApp groups:', err);
      setError('Failed to load groups');
    } finally {
      setLoading(false);
    }
  };

  const handleAddGroup = async (e) => {
    e.preventDefault();
    
    if (!newGroupName) {
      setError('Group name is required');
      return;
    }
    
    try {
      setLoading(true);
      await api.addWhatsAppGroup({
        name: newGroupName,
        description: newGroupDescription
      });
      
      // Clear form and refresh groups
      setNewGroupName('');
      setNewGroupDescription('');
      fetchGroups();
    } catch (err) {
      console.error('Error adding WhatsApp group:', err);
      setError('Failed to add group');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="whatsapp-group-manager">
      <Header title="WhatsApp Groups" />
      
      {error && <div className="error-message">{error}</div>}
      
      <div className="add-group-form">
        <h2>Add New Group</h2>
        <form onSubmit={handleAddGroup}>
          <div className="form-group">
            <label htmlFor="groupName">Group Name</label>
            <input
              type="text"
              id="groupName"
              value={newGroupName}
              onChange={(e) => setNewGroupName(e.target.value)}
              placeholder="Enter group name"
              required
            />
          </div>
          
          <div className="form-group">
            <label htmlFor="groupDescription">Description (Optional)</label>
            <textarea
              id="groupDescription"
              value={newGroupDescription}
              onChange={(e) => setNewGroupDescription(e.target.value)}
              placeholder="Enter group description"
              rows="3"
            />
          </div>
          
          <button
            type="submit"
            className="btn-primary"
            disabled={loading}
          >
            {loading ? 'Adding...' : 'Add Group'}
          </button>
        </form>
      </div>
      
      <div className="groups-list">
        <h2>Existing Groups</h2>
        {loading && <div className="loading">Loading groups...</div>}
        
        {groups.length > 0 ? (
          <ul className="groups">
            {groups.map(group => (
              <li key={group.group_id} className="group-item">
                <div className="group-info">
                  <h3>{group.name}</h3>
                  {group.description && <p>{group.description}</p>}
                </div>
              </li>
            ))}
          </ul>
        ) : (
          <p>No WhatsApp groups found. Add your first one!</p>
        )}
      </div>
      
      {/* Add a test message feature */}
      <div className="test-message-section">
        <h2>Send Test Message</h2>
        <button
          className="btn-secondary"
          onClick={async () => {
            try {
              await api.sendTestMessage({ message: "This is a test message" });
              alert("Test message sent successfully!");
            } catch (err) {
              console.error("Error sending test message:", err);
              alert("Failed to send test message");
            }
          }}
        >
          Send Test Message
        </button>
      </div>
    </div>
  );
};

export default WhatsAppGroupManager;
