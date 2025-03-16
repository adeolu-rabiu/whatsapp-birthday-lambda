import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import theme from './theme';
import Dashboard from './components/Dashboard';
import BirthdayForm from './components/BirthdayForm';
import Header from './components/Header';
import WhatsAppGroupManager from './components/WhatsAppGroupManager';
import { BirthdayProvider } from './context/BirthdayContext';
import './App.css';

// Drawer width
const DRAWER_WIDTH = 240;

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <BirthdayProvider>
        <Router>
          <Box sx={{ display: 'flex' }}>
            <Header />
            <Box
              component="main"
              sx={{
                flexGrow: 1,
                p: 3,
                width: { sm: `calc(100% - ${DRAWER_WIDTH}px)` },
                backgroundColor: 'background.default',
                minHeight: '100vh'
              }}
            >
              <Toolbar /> {/* This ensures content starts below the AppBar */}
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/add" element={<BirthdayForm />} />
                <Route path="/edit/:id" element={<BirthdayForm />} />
                <Route path="/groups" element={<WhatsAppGroupManager />} />
              </Routes>
            </Box>
          </Box>
        </Router>
      </BirthdayProvider>
    </ThemeProvider>
  );
}

export default App;
