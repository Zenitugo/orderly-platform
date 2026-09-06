const pino = require('pino');
const { trace } = require('@opentelemetry/api');
const config = require('./config');

// Base logger: plain JSON to stdout, same contract as api-gateway (slog)
// and order-worker (python json logging) so Fluent Bit treats all three
// services identically.
const baseLogger = pino({
  level: config.logLevel,
  base: { service: config.serviceName },
  timestamp: pino.stdTimeFunctions.isoTime,
  formatters: {
    level(label) {
      return { level: label };
    },
  },
});

// withTrace returns a child logger carrying trace_id/span_id from whatever
// span is currently active — the same correlation field used across all
// three services, so a log line in Kibana can be pivoted to Jaeger.
function withTrace() {
  const span = trace.getActiveSpan();
  if (!span) return baseLogger;

  const ctx = span.spanContext();
  if (!ctx || ctx.traceId === '00000000000000000000000000000000') {
    return baseLogger;
  }

  return baseLogger.child({ trace_id: ctx.traceId, span_id: ctx.spanId });
}

module.exports = { baseLogger, withTrace };