const { Kafka } = require('kafkajs');
const { trace, propagation, ROOT_CONTEXT } = require('@opentelemetry/api');
const config = require('./config');
const { withTrace } = require('./logger');
const { sendNotification } = require('./notify');

// Reads headers back out of a kafkajs message the same way order-worker
// does for the hop before this one — each header value is a Buffer in
// kafkajs, so this getter unwraps that.
const headerGetter = {
  keys(carrier) {
    return carrier ? Object.keys(carrier) : [];
  },
  get(carrier, key) {
    if (!carrier || !carrier[key]) return undefined;
    const v = carrier[key];
    return Buffer.isBuffer(v) ? v.toString('utf8') : v;
  },
};

async function startConsumer(tracer) {
  const kafka = new Kafka({
    clientId: config.serviceName,
    brokers: config.kafkaBrokers,
  });

  const consumer = kafka.consumer({ groupId: config.kafkaConsumerGroup });
  await consumer.connect();
  await consumer.subscribe({ topic: config.kafkaTopicOrdersCompleted, fromBeginning: true });

  withTrace().info({ topic: config.kafkaTopicOrdersCompleted }, 'notifier consuming');

  await consumer.run({
    eachMessage: async ({ message }) => {
      // Extract the trace context order-worker attached, so our span
      // becomes the third and final link in the same trace that started
      // in api-gateway.
      const extractedCtx = propagation.extract(ROOT_CONTEXT, message.headers, headerGetter);

      await tracer.startActiveSpan(
        'process_notification',
        {},
        extractedCtx,
        async (span) => {
          try {
            const order = JSON.parse(message.value.toString('utf8'));
            span.setAttribute('order.id', order.order_id);
            span.setAttribute('order.status', order.status);

            const result = await sendNotification(order);

            withTrace().info(
              { order_id: order.order_id, order_status: order.status, notification_sent: result.sent },
              result.sent ? 'notification sent' : 'notification send failed'
            );
          } catch (err) {
            span.recordException(err);
            withTrace().error({ error: err.message }, 'failed to process message');
          } finally {
            span.end();
          }
        }
      );
    },
  });

  return consumer;
}

module.exports = { startConsumer };