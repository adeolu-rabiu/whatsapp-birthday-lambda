import axios from 'axios';

// Load environment variables from .env
const API_URL = process.env.REACT_APP_API_URL;
const AUTH_TOKEN = process.env.REACT_APP_AUTH_TOKEN;

// Debugging: log loaded values
console.log("🔧 API URL loaded:", API_URL);
console.log("🔐 Auth Token available:", AUTH_TOKEN ? "Yes (token hidden for security)" : "No");

// Create axios instance with authorization header
const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Authorization': `Bearer ${AUTH_TOKEN}`,
    'Content-Type': 'application/json'
  }
});

// Add request interceptor for logging
apiClient.interceptors.request.use(
  config => {
    console.log(`📤 Making ${config.method.toUpperCase()} request to: ${config.baseURL}${config.url}`);
    return config;
  },
  error => {
    console.error('❌ Request error:', error);
    return Promise.reject(error);
  }
);

// Add response interceptor for logging
apiClient.interceptors.response.use(
  response => {
    console.log(`📥 Response from ${response.config.url}:`, response.status);
    return response;
  },
  error => {
    if (error.response) {
      console.error(`❌ Response error (${error.response.status}):`, error.response.data);
    } else if (error.request) {
      console.error('❌ No response received:', error.request);
    } else {
      console.error('❌ Request setup error:', error.message);
    }
    return Promise.reject(error);
  }
);

// API methods
const api = {
  getBirthdays: async () => {
    try {
      const response = await apiClient.get('/birthdays');
      return response.data;
    } catch (error) {
      console.error('Error fetching birthdays:', error);
      throw error;
    }
  },
  
  addBirthday: async (birthday) => {
    try {
      const response = await apiClient.post('/birthdays', birthday);
      return response.data;
    } catch (error) {
      console.error('Error adding birthday:', error);
      throw error;
    }
  },
  
  updateBirthday: async (id, birthday) => {
    try {
      const response = await apiClient.put(`/birthdays/${id}`, birthday);
      return response.data;
    } catch (error) {
      console.error('Error updating birthday:', error);
      throw error;
    }
  },
  
  deleteBirthday: async (id) => {
    try {
      await apiClient.delete(`/birthdays/${id}`);
      return true;
    } catch (error) {
      console.error('Error deleting birthday:', error);
      throw error;
    }
  },
  
  getWhatsAppGroups: async () => {
    try {
      const response = await apiClient.get('/groups');
      return response.data;
    } catch (error) {
      console.error('Error fetching WhatsApp groups:', error);
      throw error;
    }
  },
  
  addWhatsAppGroup: async (group) => {
    try {
      const response = await apiClient.post('/groups', group);
      return response.data;
    } catch (error) {
      console.error('Error adding WhatsApp group:', error);
      throw error;
    }
  },
  
  sendTestMessage: async (messageData) => {
    try {
      const response = await apiClient.post('/test-message', messageData);
      return response.data;
    } catch (error) {
      console.error('Error sending test message:', error);
      throw error;
    }
  }
};

export default api;
