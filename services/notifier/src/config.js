// Same pattern as api-gateway (Go) and order-worker (Python): one place
// that reads env vars, everything else imports this.
const config = {
  serviceName: process.env.SERVICE_NAME || 'notifier',
  logLevel: process.env.LOG_LEVEL || 'info',

  kafkaBrokers: (process.env.KAFKA_BROKERS || 'kafka:9092').split(','),
  kafkaTopicOrdersCompleted: process.env.KAFKA_TOPIC_ORDERS_COMPLETED || 'orders.completed',
  kafkaConsumerGroup: process.env.KAFKA_CONSUMER_GROUP || 'notifier',

  otelCollectorEndpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'otel-collector:4317',
  metricsPort: parseInt(process.env.METRICS_PORT || '9200', 10),

  // Simulated: how often "sending" the notification itself fails
  // (separate from whether the order succeeded or failed).
  simulatedNotifyFailureRate: parseFloat(process.env.SIMULATED_NOTIFY_FAILURE_RATE || '0.05'),
  simulatedSendMs: parseInt(process.env.SIMULATED_SEND_MS || '100', 10),
};

module.exports = config;