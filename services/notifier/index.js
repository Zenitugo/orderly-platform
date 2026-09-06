const { initTracer } = require('./src/telemetry');
const { startMetricsServer } = require('./src/metrics');
const { startConsumer } = require('./src/consumer');
const { baseLogger } = require('./src/logger');
const config = require('./src/config');

async function main() {
  const tracer = initTracer();

  const metricsServer = startMetricsServer(config.metricsPort);
  baseLogger.info({ port: config.metricsPort }, 'metrics server started');

  const consumer = await startConsumer(tracer);
  baseLogger.info('notifier ready');

  const shutdown = async (signal) => {
    baseLogger.info({ signal }, 'shutdown signal received');
    try {
      await consumer.disconnect();
      metricsServer.close();
    } finally {
      process.exit(0);
    }
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  baseLogger.error({ error: err.message, stack: err.stack }, 'fatal startup error');
  process.exit(1);
});