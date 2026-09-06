const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { BatchSpanProcessor } = require('@opentelemetry/sdk-trace-base');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { resourceFromAttributes } = require('@opentelemetry/resources');
const { ATTR_SERVICE_NAME } = require('@opentelemetry/semantic-conventions');
const { AsyncHooksContextManager } = require('@opentelemetry/context-async-hooks');
const { trace, context, propagation } = require('@opentelemetry/api');
const { W3CTraceContextPropagator } = require('@opentelemetry/core');

const config = require('./config');

// Mirrors the setup in api-gateway (Go) and order-worker (Python): batch
// export spans over OTLP/gRPC to the shared collector, W3C trace context
// propagator so headers written by the other two services parse correctly.
function initTracer() {
  const provider = new NodeTracerProvider({
    resource: resourceFromAttributes({
      [ATTR_SERVICE_NAME]: config.serviceName,
    }),
    spanProcessors: [
      new BatchSpanProcessor(
        new OTLPTraceExporter({
          url: `${config.otelCollectorEndpoint.startsWith('http') ? '' : 'http://'}${config.otelCollectorEndpoint}`,
        })
      ),
    ],
  });

  const contextManager = new AsyncHooksContextManager();
  contextManager.enable();
  context.setGlobalContextManager(contextManager);

  provider.register();
  propagation.setGlobalPropagator(new W3CTraceContextPropagator());

  return trace.getTracer(config.serviceName);
}

module.exports = { initTracer };