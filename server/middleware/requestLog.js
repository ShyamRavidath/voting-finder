const { performance } = require('node:perf_hooks');
const logger = require('../lib/logger');

const ENDPOINTS = new Set(['health', 'polling', 'news', 'elections']);

module.exports = (req, res, next) => {
  req.requestId = logger.requestId(req);
  const started = performance.now();
  const segment = req.path.split('/').filter(Boolean)[0];
  res.on('finish', () => {
    logger.log('info', 'request.complete', {
      requestId: req.requestId,
      endpoint: ENDPOINTS.has(segment) ? segment : 'other',
      method: req.method,
      statusCode: res.statusCode,
      latencyMs: Math.round(performance.now() - started),
      ...(res.locals.pollingTelemetry || {}),
    });
  });
  next();
};
