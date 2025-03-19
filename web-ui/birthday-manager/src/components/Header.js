import logo from '../logo.svg';
import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { 
  AppBar, 
  Toolbar, 
  Typography, 
  Box,
  Container,
  useTheme,
  Avatar,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider
} from '@mui/material';
import DashboardIcon from '@mui/icons-material/Dashboard';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import GroupsIcon from '@mui/icons-material/Groups';

// Drawer width
const DRAWER_WIDTH = 240;

function Header() {
  const theme = useTheme();
  const navigate = useNavigate();
  const location = useLocation();
  
  const menuItems = [
    { text: 'Dashboard', icon: <DashboardIcon />, path: '/' },
    { text: 'Add Birthday', icon: <AddCircleIcon />, path: '/add' },
    { text: 'WhatsApp Groups', icon: <GroupsIcon />, path: '/groups' }
  ];

  return (
    <>
      <AppBar 
        position="fixed" 
        color="primary" 
        elevation={0}
        sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}
      >
        <Container maxWidth="xl">
          <Toolbar sx={{ padding: { xs: 1, sm: 2 }, justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Avatar 
                src={logo}
                alt="Logo"
                sx={{ 
                  width: 30, 
                  height: 30, 
                  mr: 1
                }}
              />
              <Typography 
                variant="h5" 
                component="div" 
                sx={{ 
                  fontWeight: 'bold',
                  display: { xs: 'none', sm: 'block' }
                }}
              >
                Birthday Reminder
              </Typography>
            </Box>
            
            {/* Logo on the right */}
            <Avatar 
              src={logo}
              alt="Birthday Reminder"
              sx={{ 
                width: 70, 
                height: 70, 
                bgcolor: theme.palette.primary.main
              }}
            />
          </Toolbar>
        </Container>
      </AppBar>
      
      {/* Side Navigation Drawer */}
      <Drawer
        variant="permanent"
        sx={{
          width: DRAWER_WIDTH,
          flexShrink: 0,
          [`& .MuiDrawer-paper`]: { 
            width: DRAWER_WIDTH, 
            boxSizing: 'border-box',
            backgroundColor: theme.palette.background.paper,
            borderRight: `1px solid ${theme.palette.divider}`
          },
        }}
      >
        <Toolbar /> {/* This ensures content starts below the AppBar */}
        <Box sx={{ overflow: 'auto', mt: 2 }}>
          <List>
            {menuItems.map((item) => (
              <ListItem 
                button 
                key={item.text}
                onClick={() => navigate(item.path)}
                selected={location.pathname === item.path}
                sx={{
                  mb: 1,
                  borderRadius: '0 20px 20px 0',
                  mr: 2,
                  '&.Mui-selected': {
                    backgroundColor: `${theme.palette.primary.main}20`,
                    color: theme.palette.primary.main,
                    '&:hover': {
                      backgroundColor: `${theme.palette.primary.main}30`,
                    },
                  },
                  '&:hover': {
                    backgroundColor: `${theme.palette.primary.main}10`,
                  }
                }}
              >
                <ListItemIcon 
                  sx={{ 
                    color: location.pathname === item.path ? 
                      theme.palette.primary.main : 'inherit',
                    minWidth: 40
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                <ListItemText primary={item.text} />
              </ListItem>
            ))}
          </List>
          <Divider />
        </Box>
      </Drawer>
    </>
  );
}

export default Header;
