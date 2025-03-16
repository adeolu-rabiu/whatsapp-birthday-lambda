import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Formik, Form, Field } from 'formik';
import * as Yup from 'yup';
import { 
  Box, 
  Button, 
  TextField, 
  Typography, 
  MenuItem, 
  Paper,
  Grid,
  CircularProgress,
  Snackbar,
  Alert,
  FormControl,
  InputLabel,
  Select,
  FormHelperText,
  useTheme
} from '@mui/material';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { LocalizationProvider, DatePicker } from '@mui/x-date-pickers';
import SaveIcon from '@mui/icons-material/Save';
import CancelIcon from '@mui/icons-material/Cancel';
import { useBirthdays } from '../context/BirthdayContext';

// Validation schema
const BirthdaySchema = Yup.object().shape({
  name: Yup.string()
    .min(2, 'Name is too short')
    .max(50, 'Name is too long')
    .required('Name is required'),
  birthDate: Yup.date()
    .required('Birth date is required')
    .max(new Date(), 'Birth date cannot be in the future'),
  group: Yup.string()
    .required('Group is required'),
  notes: Yup.string()
    .max(200, 'Notes cannot exceed 200 characters')
});

function BirthdayForm() {
  const theme = useTheme();
  const { id } = useParams();
  const navigate = useNavigate();
  const [birthday, setBirthday] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const isEditMode = Boolean(id);

  // Use the context to get data and functions
  const { 
    groups, 
    addBirthday, 
    updateBirthday, 
    getBirthday 
  } = useBirthdays();

  useEffect(() => {
    // If in edit mode, get the birthday data from context
    if (isEditMode) {
      const found = getBirthday(id);
      if (found) {
        setBirthday(found);
      } else {
        setError('Birthday not found');
        navigate('/');
      }
    }
    
    setLoading(false);
  }, [id, isEditMode, navigate, getBirthday]);

  const handleSubmit = async (values, { setSubmitting }) => {
    try {
      setLoading(true);
      
      if (isEditMode) {
        updateBirthday(id, values);
      } else {
        addBirthday(values);
      }
      
      setSuccess(true);
      setTimeout(() => {
        navigate('/');
      }, 1500);
    } catch (err) {
      setError('Failed to save birthday. Please try again.');
    } finally {
      setLoading(false);
      setSubmitting(false);
    }
  };

  if (loading && isEditMode) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
        <CircularProgress color="primary" />
      </Box>
    );
  }

  const initialValues = birthday || {
    name: '',
    birthDate: '',
    group: '',
    notes: ''
  };

  return (
    <Box sx={{ maxWidth: 800, mx: 'auto' }}>
      <Paper 
        elevation={2} 
        sx={{ 
          p: 4, 
          borderRadius: 3,
          mb: 4,
          background: `linear-gradient(120deg, ${theme.palette.primary.main}, ${theme.palette.secondary.main})`,
          color: 'white'
        }}
      >
        <Typography variant="h4" component="h1" gutterBottom>
          {isEditMode ? 'Edit Birthday' : 'Add New Birthday'}
        </Typography>
        <Typography variant="subtitle1">
          {isEditMode ? 'Update the birthday information' : 'Enter the birthday details'}
        </Typography>
      </Paper>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>
      )}

      <Paper elevation={2} sx={{ p: 4, borderRadius: 2 }}>
        <Formik
          initialValues={initialValues}
          validationSchema={BirthdaySchema}
          onSubmit={handleSubmit}
          enableReinitialize
        >
          {({ values, errors, touched, isSubmitting, handleChange, setFieldValue }) => (
            <Form>
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <Field
                    as={TextField}
                    fullWidth
                    label="Name"
                    name="name"
                    variant="outlined"
                    error={touched.name && Boolean(errors.name)}
                    helperText={touched.name && errors.name}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth error={touched.group && Boolean(errors.group)}>
                    <InputLabel id="group-label">Group</InputLabel>
                    <Field
                      as={Select}
                      labelId="group-label"
                      name="group"
                      label="Group"
                      value={values.group}
                      onChange={handleChange}
                    >
                      {groups.map((group) => (
                        <MenuItem key={group.id} value={group.id}>
                          {group.name}
                        </MenuItem>
                      ))}
                    </Field>
                    {touched.group && errors.group && (
                      <FormHelperText>{errors.group}</FormHelperText>
                    )}
                  </FormControl>
                </Grid>

                <Grid item xs={12} sm={6}>
                  <LocalizationProvider dateAdapter={AdapterDateFns}>
                    <DatePicker
                      label="Birth Date"
                      value={values.birthDate}
                      onChange={(newValue) => {
                        setFieldValue('birthDate', newValue);
                      }}
                      renderInput={(params) => (
                        <TextField
                          {...params}
                          fullWidth
                          name="birthDate"
                          error={touched.birthDate && Boolean(errors.birthDate)}
                          helperText={touched.birthDate && errors.birthDate}
                        />
                      )}
                    />
                  </LocalizationProvider>
                </Grid>

                <Grid item xs={12}>
                  <Field
                    as={TextField}
                    fullWidth
                    label="Notes"
                    name="notes"
                    variant="outlined"
                    multiline
                    rows={4}
                    error={touched.notes && Boolean(errors.notes)}
                    helperText={touched.notes && errors.notes}
                  />
                </Grid>

                <Grid item xs={12}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 2 }}>
                    <Button
                      variant="outlined"
                      color="primary"
                      startIcon={<CancelIcon />}
                      onClick={() => navigate('/')}
                    >
                      Cancel
                    </Button>
                    <Button
                      variant="contained"
                      color="primary"
                      startIcon={<SaveIcon />}
                      type="submit"
                      disabled={isSubmitting || loading}
                    >
                      {(isSubmitting || loading) ? (
                        <CircularProgress size={24} color="inherit" />
                      ) : (
                        isEditMode ? 'Update' : 'Save'
                      )}
                    </Button>
                  </Box>
                </Grid>
              </Grid>
            </Form>
          )}
        </Formik>
      </Paper>

      <Snackbar
        open={success}
        autoHideDuration={3000}
        onClose={() => setSuccess(false)}
      >
        <Alert severity="success" sx={{ width: '100%' }}>
          {isEditMode ? 'Birthday updated successfully!' : 'Birthday added successfully!'}
        </Alert>
      </Snackbar>
    </Box>
  );
}

export default BirthdayForm;
