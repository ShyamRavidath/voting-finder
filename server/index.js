const app = require('./app');
const logger = require('./lib/logger');

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => logger.log('info', 'server.listening', { port: PORT }));
