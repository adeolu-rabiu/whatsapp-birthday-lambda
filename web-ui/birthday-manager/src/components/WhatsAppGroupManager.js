import React, { useState } from 'react';
import { 
  Box, 
  Typography, 
  Button, 
  Card, 
  CardContent, 
  Grid, 
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Paper,
  useTheme
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import WhatsAppIcon from '@mui/icons-material/WhatsApp';
import PeopleIcon from '@mui/icons-material/People';
import { useBirthdays } from '../context/BirthdayContext';

function WhatsAppGroupManager() {
  const theme = useTheme();
  const { groups, addGroup, updateGroup, deleteGroup, getBirthdaysByGroup } = useBirthdays();
  
  const [openDialog, setOpenDialog] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [currentGroup, setCurrentGroup] = useState({ id: '', name: '', description: '', memberCount: 0 });
  const [dialogError, setDialogError] = useState('');

  const handleOpenAddDialog = () => {
    setCurrentGroup({ id: '', name: '', description: '', memberCount: 0 });
    setIsEditing(false);
    setDialogError('');
    setOpenDialog(true);
  };

  const handleOpenEditDialog = (group) => {
    setCurrentGroup({
      id: group.id,
      name: group.name,
      description: group.description || '',
      memberCount: group.memberCount || 0
    });
    setIsEditing(true);
    setDialogError('');
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setCurrentGroup({
      ...currentGroup,
      [name]: value
    });
  };

  const handleSubmit = () => {
    if (!currentGroup.name.trim()) {
      setDialogError('Group name is required');
      return;
    }

    try {
      if (isEditing) {
        updateGroup(currentGroup.id, currentGroup);
      } else {
        addGroup(currentGroup);
      }
      handleCloseDialog();
    } catch (error) {
      setDialogError('Failed to save group. Please try again.');
    }
  };

  const handleDelete = (id) => {
    // Check if any birthdays are using this group
    const birthdaysInGroup = getBirthdaysByGroup(id);
    
    if (birthdaysInGroup.length > 0) {
      alert(`Cannot delete this group. It is associated with ${birthdaysInGroup.length} birthdays.`);
      return;
    }
    
    if (window.confirm('Are you sure you want to delete this group?')) {
      deleteGroup(id);
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
            WhatsApp Groups
          </Typography>
          <Typography variant="subtitle1">
            Manage your WhatsApp groups for birthday notifications
          </Typography>
        </Box>
        <Button
          variant="contained"
          color="secondary"
          onClick={handleOpenAddDialog}
          startIcon={<AddIcon />}
          sx={{ bgcolor: 'white', color: theme.palette.primary.main }}
        >
          Add Group
        </Button>
      </Paper>

      {/* Display Groups */}
      <Grid container spacing={3}>
        {groups.map((group) => (
          <Grid item xs={12} sm={6} md={4} key={group.id}>
            <Card elevation={1} sx={{ borderRadius: 2, height: '100%' }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <WhatsAppIcon sx={{ color: '#25D366', mr: 1 }} />
                  <Typography variant="h6" component="div">
                    {group.name}
                  </Typography>
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {group.description || 'No description available'}
                </Typography>

                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <PeopleIcon sx={{ fontSize: 16, mr: 0.5, color: 'text.secondary' }} />
                  <Typography variant="body2" color="text.secondary">
                    {group.memberCount || 0} members
                  </Typography>
                </Box>

                <Box sx={{ display: 'flex', mt: 2, justifyContent: 'flex-start' }}>
                  <IconButton 
                    size="small"
                    color="primary"
                    sx={{ mr: 1 }}
                    onClick={() => handleOpenEditDialog(group)}
                  >
                    <EditIcon fontSize="small" />
                  </IconButton>
                  <IconButton 
                    size="small"
                    color="error"
                    onClick={() => handleDelete(group.id)}
                  >
                    <DeleteIcon fontSize="small" />
                  </IconButton>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Add/Edit Dialog */}
      <Dialog open={openDialog} onClose={handleCloseDialog} fullWidth maxWidth="sm">
        <DialogTitle>{isEditing ? 'Edit WhatsApp Group' : 'Add WhatsApp Group'}</DialogTitle>
        <DialogContent>
          {dialogError && (
            <Typography color="error" variant="body2" sx={{ mb: 2 }}>
              {dialogError}
            </Typography>
          )}
          <TextField
            autoFocus
            margin="dense"
            name="name"
            label="Group Name"
            type="text"
            fullWidth
            variant="outlined"
            value={currentGroup.name}
            onChange={handleChange}
            required
            sx={{ mb: 2 }}
          />
          <TextField
            margin="dense"
            name="description"
            label="Description"
            type="text"
            fullWidth
            variant="outlined"
            value={currentGroup.description}
            onChange={handleChange}
            multiline
            rows={3}
            sx={{ mb: 2 }}
          />
          <TextField
            margin="dense"
            name="memberCount"
            label="Number of Members"
            type="number"
            fullWidth
            variant="outlined"
            value={currentGroup.memberCount}
            onChange={handleChange}
            InputProps={{ inputProps: { min: 0 } }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button onClick={handleSubmit} variant="contained" color="primary">
            {isEditing ? 'Update' : 'Add'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default WhatsAppGroupManager;
