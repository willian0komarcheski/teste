const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const axios = require('axios'); // You'll need to add axios as a dependency

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Service URLs
const AUTH_API_URL = process.env.AUTH_API_URL || 'http://auth_api:8000/api';
const RECORD_API_URL = process.env.RECORD_API_URL || 'http://record_api:5001';

// Middlewares
app.use(cors());
app.use(express.json());

// Token verification middleware
async function verifyToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const response = await axios.post(`${AUTH_API_URL}/verify-token`, { token });
    req.user = response.data;
    next();
  } catch (error) {
    console.error('Token verification failed:', error.message);
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// Routes
app.get('/', (req, res) => {
  res.send('Receive-Send API está funcionando');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Protected route that requires token verification
app.post('/send', verifyToken, async (req, res) => {
  const { from, to, message } = req.body;

  if (!from || !to || !message) {
    return res.status(400).json({ error: 'Parâmetros obrigatórios: from, to, message' });
  }

  try {
    // Send message to record API
    const recordResponse = await axios.post(`${RECORD_API_URL}/messages`, {
      from,
      to,
      message
    });

    console.log(`Mensagem recebida de ${from} para ${to}: ${message}`);

    res.status(200).json({ 
      status: 'mensagem recebida e gravada',
      dados: { from, to, message },
      record: recordResponse.data 
    });
  } catch (error) {
    console.error('Error sending message to record API:', error.message);
    res.status(500).json({ 
      error: 'Failed to record message',
      details: error.message 
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something broke!' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});