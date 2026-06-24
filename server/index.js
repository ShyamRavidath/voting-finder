require('dotenv').config();
const express = require('express');
const corsMiddleware = require('./middleware/cors');
const rateLimit = require('./middleware/rateLimit');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(corsMiddleware);
app.use(express.json());
app.use(rateLimit);

app.use('/api/news', require('./routes/news'));
app.use('/api/polling', require('./routes/polling'));
app.use('/api/elections', require('./routes/elections'));

app.get('/api/health', (_, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

module.exports = app;
