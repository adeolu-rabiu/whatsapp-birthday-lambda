import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod';

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
  }
};

export default api;
