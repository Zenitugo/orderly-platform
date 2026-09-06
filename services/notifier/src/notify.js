const { trace } = require('@opentelemetry/api');
const config = require('./config');
const { notificationsSentTotal, notificationSendSeconds } = require('./metrics');

const tracer = trace.getTracer(config.serviceName);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Simulates calling out to an email/SMS provider. Wrapped in its own span
// (a child of process_notification) so Jaeger shows this as a distinct
// timed step — the same way a real provider call would show up.
async function sendNotification(order) {
  return tracer.startActiveSpan('send_notification', async (span) => {
    const end = notificationSendSeconds.startTimer();
    span.setAttribute('order.id', order.order_id);
    span.setAttribute('order.status', order.status);

    try {
      await sleep(config.simulatedSendMs);

      const sendFailed = Math.random() < config.simulatedNotifyFailureRate;
      if (sendFailed) {
        throw new Error('simulated notification provider timeout');
      }

      notificationsSentTotal.labels('sent').inc();
      span.setAttribute('notification.outcome', 'sent');
      return { sent: true };
    } catch (err) {
      notificationsSentTotal.labels('failed').inc();
      span.recordException(err);
      span.setAttribute('notification.outcome', 'failed');
      return { sent: false, error: err.message };
    } finally {
      end();
      span.end();
    }
  });
}

module.exports = { sendNotification };