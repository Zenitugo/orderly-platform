# api-gateway

Entry point for the Orderly system. Accepts order requests over HTTP,
validates them, and publishes an `OrderCreatedEvent` to Kafka for
`order-worker` to pick up. Deliberately does no business logic itself —
it's a thin, fast front door.

## Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/orders` | Create an order. Body: `{"customer_id": "...", "item": "...", "quantity": 1}`. Returns `202 Accepted`. |
| GET | `/orders/{id}` | Placeholder — order state lives in order-worker, not wired up yet. |
| GET | `/healthz` | Liveness probe. |
| GET | `/metrics` | Prometheus scrape endpoint. |

## Env vars

| Var | Default | Purpose |
|---|---|---|
| `SERVICE_NAME` | `api-gateway` | Used in OTel resource attributes and logs. |
| `HTTP_PORT` | `8080` | Port to listen on. |
| `LOG_LEVEL` | `info` | `debug` / `info` / `warn` / `error`. |
| `KAFKA_BROKERS` | `kafka:9092` | Comma-separated broker list. |
| `KAFKA_TOPIC_ORDERS_CREATED` | `orders.created` | Topic this service produces to. |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `otel-collector:4317` | Where traces are shipped (gRPC). |

## Observability notes (useful for blog writeups)

- **Tracing**: every HTTP request gets a span via `otelhttp`. When an order
  is published to Kafka, the trace context is injected into the Kafka
  message headers (W3C `traceparent` format) — this is what lets the trace
  continue into `order-worker` on the other side of the queue, instead of
  starting a brand new disconnected trace per service.
- **Logs**: JSON structured via `slog`, with `trace_id`/`span_id` attached
  to every log line inside a request — this is the field Kibana and Jaeger
  share, so you can pivot from a log line straight to its trace.
- **Metrics**: custom counters `orders_created_total`, `orders_rejected_total`,
  plus Kafka producer counters, all exposed at `/metrics` for Prometheus.

## Local build

```bash
go mod tidy   # resolves go.sum — requires network access to proxy.golang.org
go build ./...
go run .
```

## Docker build

```bash
docker build -t orderly/api-gateway:local .
```