import React from 'react';
import { Link } from 'react-router-dom';

const Header = ({ title }) => {
  return (
    <header className="app-header">
      <h1>{title}</h1>
      <nav className="main-nav">
        <Link to="/">Dashboard</Link>
        <Link to="/add">Add Birthday</Link>
        <Link to="/groups">WhatsApp Groups</Link>
      </nav>
    </header>
  );
};

export default Header;
