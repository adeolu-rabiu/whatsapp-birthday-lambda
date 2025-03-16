import React from 'react';
import { Link } from 'react-router-dom';
import { 
  Box, 
  Typography, 
  Button, 
  Card, 
  CardContent, 
  Grid, 
  Chip, 
  IconButton,
  Paper,
  useTheme
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import { useBirthdays } from '../context/BirthdayContext';

function Dashboard() {
  const theme = useTheme();
  const { birthdays, groups, deleteBirthday, getUpcomingBirthdays } = useBirthdays();
  const upcomingBirthdays = getUpcomingBirthdays();

  // Function to calculate days until birthday
  const getDaysUntilBirthday = (birthDateStr) => {
    const today = new Date();
    const birthDate = new Date(birthDateStr);
    const currentYear = today.getFullYear();
    
    // Set birth date to this year
    const thisYearBirthday = new Date(
      currentYear,
      birthDate.getMonth(),
      birthDate.getDate()
    );
    
    // If birthday has already passed this year, calculate for next year
    if (thisYearBirthday < today) {
      thisYearBirthday.setFullYear(currentYear + 1);
    }
    
    // Calculate difference in days
    const diffTime = thisYearBirthday - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    return diffDays;
  };

  // Function to get age from birth date
  const getAge = (birthDateStr) => {
    const birthDate = new Date(birthDateStr);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
  };

  // Function to get the group name from ID
  const getGroupName = (groupId) => {
    const group = groups.find(g => g.id === groupId);
    return group ? group.name : groupId; // Fallback to ID if not found
  };

  const handleDelete = (id, event) => {
    event.stopPropagation();
    if (window.confirm('Are you sure you want to delete this birthday?')) {
      deleteBirthday(id);
    }
  };

  return (
    <Box>
      <Paper
        elevation={0}
        sx={{
          p: 3,
          mb: 4,
          borderRadius: 2,
          background: `linear-gradient(120deg, ${theme.palette.primary.main}, ${theme.palette.secondary.main})`,
          color: 'white',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}
      >
        <Box>
          <Typography variant="h4" component="h1" gutterBottom>
            Birthday Dashboard
          </Typography>
          <Typography variant="subtitle1">
            Keep track of all your important dates
          </Typography>
        </Box>
        <Button
          component={Link}
          to="/add"
          variant="contained"
          color="secondary"
          startIcon={<AddIcon />}
          sx={{ bgcolor: 'white', color: theme.palette.primary.main }}
        >
          Add Birthday
        </Button>
      </Paper>

      {/* Upcoming Birthdays */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5" component="h2" gutterBottom sx={{ mb: 2 }}>
          Upcoming Birthdays
        </Typography>
        
        {upcomingBirthdays.length === 0 ? (
          <Paper sx={{ p: 3, borderRadius: 2, bgcolor: '#f5f5f5' }}>
            <Typography variant="body1">No upcoming birthdays in the next 30 days.</Typography>
          </Paper>
        ) : (
          <Grid container spacing={3}>
            {upcomingBirthdays.map((birthday) => (
              <Grid item xs={12} sm={6} md={4} key={birthday.id}>
                <Card 
                  elevation={2} 
                  sx={{ 
                    borderRadius: 2,
                    bgcolor: theme.palette.success.light,
                    color: 'white',
                    height: '100%'
                  }}
                >
                  <CardContent>
                    <Box sx={{ display: 'flex', mb: 1, alignItems: 'center' }}>
                      <Box sx={{ 
                        width: 40, 
                        height: 40, 
                        borderRadius: '50%', 
                        bgcolor: 'white',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        mr: 2,
                        color: theme.palette.success.main
                      }}>
                        <Typography variant="h6">{getAge(birthday.birthDate)}</Typography>
                      </Box>
                      <Box>
                        <Typography variant="h6" component="div">
                          {birthday.name}
                        </Typography>
                        <Typography variant="body2">
                          {new Date(birthday.birthDate).toLocaleDateString('en-US', {
                            month: 'long',
                            day: 'numeric',
                            year: 'numeric'
                          })}
                        </Typography>
                      </Box>
                    </Box>
                    
                    <Box sx={{ display: 'flex', mt: 2, mb: 1, justifyContent: 'space-between', alignItems: 'center' }}>
                      <Chip 
                        label={getGroupName(birthday.group)} 
                        size="small" 
                        sx={{ 
                          bgcolor: 'rgba(255,255,255,0.3)', 
                          color: 'white',
                          '& .MuiChip-label': { px: 1 }
                        }} 
                      />
                      <Chip 
                        label={`${getDaysUntilBirthday(birthday.birthDate)} days`} 
                        size="small"
                        sx={{ 
                          bgcolor: 'white', 
                          color: theme.palette.success.dark,
                          fontWeight: 'bold',
                          '& .MuiChip-label': { px: 1 }
                        }} 
                      />
                    </Box>
                    
                    {birthday.notes && (
                      <Typography variant="body2" sx={{ mt: 1, mb: 1, color: 'rgba(255,255,255,0.9)' }}>
                        {birthday.notes}
                      </Typography>
                    )}
                    
                    <Box sx={{ display: 'flex', mt: 2, justifyContent: 'flex-start' }}>
                      <IconButton 
                        component={Link} 
                        to={`/edit/${birthday.id}`} 
                        size="small"
                        sx={{ color: 'white', mr: 1 }}
                      >
                        <EditIcon fontSize="small" />
                      </IconButton>
                      <IconButton 
                        size="small"
                        sx={{ color: 'white' }}
                        onClick={(e) => handleDelete(birthday.id, e)}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Box>

      {/* All Birthdays */}
      <Box>
        <Typography variant="h5" component="h2" gutterBottom sx={{ mb: 2 }}>
          All Birthdays
        </Typography>
        
        {birthdays.length === 0 ? (
          <Paper sx={{ p: 3, borderRadius: 2, bgcolor: '#f5f5f5' }}>
            <Typography variant="body1">
              You haven't added any birthdays yet. Click the "Add Birthday" button to get started.
            </Typography>
          </Paper>
        ) : (
          <Grid container spacing={3}>
            {birthdays.map((birthday) => (
              <Grid item xs={12} sm={6} md={4} key={birthday.id}>
                <Card elevation={1} sx={{ borderRadius: 2, height: '100%' }}>
                  <CardContent>
                    <Typography variant="h6" component="div">
                      {birthday.name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      {new Date(birthday.birthDate).toLocaleDateString('en-US', {
                        month: 'long',
                        day: 'numeric',
                        year: 'numeric'
                      })}
                    </Typography>
                    
                    <Chip 
                      label={getGroupName(birthday.group)} 
                      size="small" 
                      sx={{ mt: 1, mb: 1 }} 
                    />
                    
                    <Box sx={{ display: 'flex', mt: 2, justifyContent: 'flex-start' }}>
                      <IconButton 
                        component={Link} 
                        to={`/edit/${birthday.id}`} 
                        size="small"
                        color="primary"
                        sx={{ mr: 1 }}
                      >
                        <EditIcon fontSize="small" />
                      </IconButton>
                      <IconButton 
                        size="small"
                        color="error"
                        onClick={(e) => handleDelete(birthday.id, e)}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Box>
    </Box>
  );
}

export default Dashboard;
