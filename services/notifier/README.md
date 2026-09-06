# notifier

Consumes `orders.completed` from Kafka and simulates sending a customer
notification (email/SMS provider call, faked). This is the third and final
service in the Orderly request path.

## The trace, end to end

This is the payoff service for the tracing story:

1. `api-gateway` (Go) starts the trace on `POST /orders`, injects
   `traceparent` into the Kafka message it produces.
2. `order-worker` (Python) extracts that header, continues the trace as a
   child span, does its work, injects `traceparent` again when it produces
   to `orders.completed`.
3. `notifier` (this service) extracts it one more time, so
   `process_notification` and `send_notification` show up as the final
   spans in the **same** trace that started in api-gateway.

One request, three languages, three processes, one trace in Jaeger. That
continuity — not any single span — is the thing worth screenshotting.

## Env vars

| Var | Default | Purpose |
|---|---|---|
| `SERVICE_NAME` | `notifier` | OTel resource name / log field |
| `LOG_LEVEL` | `info` | pino log level |
| `KAFKA_BROKERS` | `kafka:9092` | Broker list |
| `KAFKA_TOPIC_ORDERS_COMPLETED` | `orders.completed` | Consumed topic |
| `KAFKA_CONSUMER_GROUP` | `notifier` | Consumer group id |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `otel-collector:4317` | Trace export target |
| `METRICS_PORT` | `9200` | Prometheus scrape + `/healthz` port |
| `SIMULATED_NOTIFY_FAILURE_RATE` | `0.05` | Fraction of sends that fail |
| `SIMULATED_SEND_MS` | `100` | Artificial send delay |

## Metrics (`:9200/metrics`)

- `notifications_sent_total{outcome="sent"|"failed"}`
- `notification_send_seconds` (histogram)
- default Node process metrics (event loop lag, memory, etc. via `prom-client`)

## Local run

```bash
npm install
node index.js
```

Requires a reachable Kafka broker — see the docker-compose file at the repo
root once that's set up.

