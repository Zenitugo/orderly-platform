const client = require('prom-client');
const http = require('http');

const notificationsSentTotal = new client.Counter({
  name: 'notifications_sent_total',
  help: 'Total notifications attempted, by outcome.',
  labelNames: ['outcome'],
});

const notificationSendSeconds = new client.Histogram({
  name: 'notification_send_seconds',
  help: 'Time spent simulating a notification send.',
});

client.collectDefaultMetrics();

function startMetricsServer(port) {
  const server = http.createServer(async (req, res) => {
    if (req.url === '/metrics') {
      res.setHeader('Content-Type', client.register.contentType);
      res.end(await client.register.metrics());
      return;
    }
    if (req.url === '/healthz') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok' }));
      return;
    }
    res.writeHead(404);
    res.end();
  });
  server.listen(port);
  return server;
}

module.exports = { notificationsSentTotal, notificationSendSeconds, startMetricsServer };