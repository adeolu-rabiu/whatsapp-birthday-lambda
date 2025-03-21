import axios from 'axios';

// Update this URL with the actual API Gateway URL after Terraform deployment
const API_URL = process.env.REACT_APP_API_URL || 'https://s9i0mo0564.execute-api.eu-west-2.amazonaws.com/$default';

const api = {
  getBirthdays: async () => {
    try {
      const response = await axios.get(`${API_URL}/birthdays`);
      return response.data;
    } catch (error) {
      console.error('Error fetching birthdays:', error);
      throw error;
    }
  },
  
  addBirthday: async (birthday) => {
    try {
      const response = await axios.post(`${API_URL}/birthdays`, birthday);
      return response.data;
    } catch (error) {
      console.error('Error adding birthday:', error);
      throw error;
    }
  },
  
  updateBirthday: async (id, birthday) => {
    try {
      const response = await axios.put(`${API_URL}/birthdays/${id}`, birthday);
      return response.data;
    } catch (error) {
      console.error('Error updating birthday:', error);
      throw error;
    }
  },
  
  deleteBirthday: async (id) => {
    try {
      await axios.delete(`${API_URL}/birthdays/${id}`);
      return true;
    } catch (error) {
      console.error('Error deleting birthday:', error);
      throw error;
    }
  },
  
  getWhatsAppGroups: async () => {
    try {
      const response = await axios.get(`${API_URL}/groups`);
      return response.data;
    } catch (error) {
      console.error('Error fetching WhatsApp groups:', error);
      throw error;
    }
  },
  
  addWhatsAppGroup: async (group) => {
    try {
      const response = await axios.post(`${API_URL}/groups`, group);
      return response.data;
    } catch (error) {
      console.error('Error adding WhatsApp group:', error);
      throw error;
    }
  },
  
  // New method for testing WhatsApp messages
  sendTestMessage: async (messageData) => {
    try {
      const response = await axios.post(`${API_URL}/test-message`, messageData);
      return response.data;
    } catch (error) {
      console.error('Error sending test message:', error);
      throw error;
    }
  }
};

export default api;
