import React from 'react';
import { BrowserRouter as Router, Routes, Route, NavLink } from 'react-router-dom';
import Dashboard from './components/Dashboard';
import BirthdayForm from './components/BirthdayForm';
import WhatsAppGroupManager from './components/WhatsAppGroupManager';
import ClearStorage from './components/ClearStorage';
import './App.css';

function App() {
  return (
    <Router>
      <div className="app">
        {/* WhatsApp-styled sidebar */}
        <nav className="sidebar">
          <div className="logo">
            <span role="img" aria-label="birthday">🎂</span> Birthday Reminder
          </div>
          <ul>
            <li>
              <NavLink to="/" className={({ isActive }) => isActive ? "active" : ""}>
                <span role="img" aria-label="dashboard">📊</span> Dashboard
              </NavLink>
            </li>
            <li>
              <NavLink to="/add" className={({ isActive }) => isActive ? "active" : ""}>
                <span role="img" aria-label="add">➕</span> Add Birthday
              </NavLink>
            </li>
            <li>
              <NavLink to="/whatsapp-groups" className={({ isActive }) => isActive ? "active" : ""}>
                <span role="img" aria-label="groups">👥</span> WhatsApp Groups
              </NavLink>
            </li>
          </ul>
        </nav>
        
        {/* Main content area */}
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/add" element={<BirthdayForm />} />
            <Route path="/edit/:id" element={<BirthdayForm />} />
            <Route path="/whatsapp-groups" element={<WhatsAppGroupManager />} />
          </Routes>
        </main>
        
        {/* Clear Storage button at bottom right */}
        <ClearStorage />
      </div>
    </Router>
  );
}

export default App;
