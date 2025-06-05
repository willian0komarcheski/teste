const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Rotas
app.get('/', (req, res) => {
  res.send('Receive-Send API está funcionando');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Inicia o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

app.post('/send', (req, res) => {
  const { from, to, message } = req.body;

  if (!from || !to || !message) {
    return res.status(400).json({ error: 'Parâmetros obrigatórios: from, to, message' });
  }

  // Aqui você poderia chamar um serviço, salvar em banco, enviar para fila etc.
  console.log(`Mensagem recebida de ${from} para ${to}: ${message}`);

  res.status(200).json({ status: 'mensagem recebida', dados: { from, to, message } });
});
