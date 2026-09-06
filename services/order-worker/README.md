# order-worker

Consumes `orders.created` from Kafka, "processes" the order (simulated work
+ a configurable random failure rate), writes final state to Postgres, and
publishes `orders.completed` for `notifier` to react to.

## Why a single `orders.completed` topic instead of separate success/failure topics

Simpler for `notifier` to consume from one place, and the `status` field
(`completed` / `failed`) carries the distinction. If this were a bigger
system I'd reconsider — dedicated `orders.failed` gives you cleaner
per-topic Kafka consumer lag metrics — but for a demo of this size, one
topic is the right amount of complexity.

## The trace propagation detail (worth a blog paragraph)

`api-gateway` injects a W3C `traceparent` into the Kafka message headers
when it produces to `orders.created`. This service extracts that same
header on consume and starts its span as a **child of that context**
(`consumer.py::_handle_message`), not a fresh trace. That's the difference
between "three services that each happen to use OpenTelemetry" and "one
distributed trace you can follow end-to-end in Jaeger" — the second one is
what's actually hard to get right and worth demonstrating.

## Env vars

| Var | Default | Purpose |
|---|---|---|
| `SERVICE_NAME` | `order-worker` | OTel resource name / log field |
| `LOG_LEVEL` | `info` | debug/info/warning/error |
| `KAFKA_BROKERS` | `kafka:9092` | Broker list |
| `KAFKA_TOPIC_ORDERS_CREATED` | `orders.created` | Consumed topic |
| `KAFKA_TOPIC_ORDERS_COMPLETED` | `orders.completed` | Produced topic |
| `KAFKA_CONSUMER_GROUP` | `order-worker` | Consumer group id |
| `POSTGRES_DSN` | `host=postgres port=5432 dbname=orderly user=orderly password=orderly` | Full psycopg2 DSN |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `otel-collector:4317` | Trace export target |
| `METRICS_PORT` | `9100` | Prometheus scrape port |
| `SIMULATED_FAILURE_RATE` | `0.1` | Fraction of orders that "fail" (0.0–1.0) |
| `SIMULATED_PROCESSING_MS` | `250` | Artificial processing delay |

## Metrics exposed (`:9100/metrics`)

- `orders_processed_total{status="completed"|"failed"}`
- `order_processing_seconds` (histogram)
- `kafka_consume_errors_total`

## Local run

```bash
pip install -r requirements.txt
python main.py
```

Requires a reachable Kafka broker and Postgres instance — see the
docker-compose file at the repo root once that's set up.