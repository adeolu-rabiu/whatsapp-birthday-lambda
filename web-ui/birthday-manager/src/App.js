import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Dashboard from './components/Dashboard';
import BirthdayForm from './components/BirthdayForm';
import WhatsAppGroupManager from './components/WhatsAppGroupManager';
import ClearStorage from './components/ClearStorage';
import './App.css'; // Make sure you have this CSS file

function App() {
  return (
    <Router>
      <div className="app">
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/add" element={<BirthdayForm />} />
            <Route path="/edit/:id" element={<BirthdayForm />} />
            <Route path="/whatsapp-groups" element={<WhatsAppGroupManager />} />
          </Routes>
        </main>
        <ClearStorage />
      </div>
    </Router>
  );
}

export default App;
