import os


class Config:
    """Centralized env var loading, mirrors the pattern used in api-gateway."""

    def __init__(self):
        self.service_name = os.getenv("SERVICE_NAME", "order-worker")
        self.log_level = os.getenv("LOG_LEVEL", "info")

        self.kafka_brokers = os.getenv("KAFKA_BROKERS", "kafka:9092")
        self.kafka_topic_orders_created = os.getenv("KAFKA_TOPIC_ORDERS_CREATED", "orders.created")
        self.kafka_topic_orders_completed = os.getenv("KAFKA_TOPIC_ORDERS_COMPLETED", "orders.completed")
        self.kafka_consumer_group = os.getenv("KAFKA_CONSUMER_GROUP", "order-worker")

        self.postgres_dsn = os.getenv(
            "POSTGRES_DSN",
            "host=postgres port=5432 dbname=orderly user=orderly password=orderly",
        )

        self.otel_collector_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "otel-collector:4317")
        self.metrics_port = int(os.getenv("METRICS_PORT", "9100"))

        # Simulated failure rate (0.0 - 1.0). Real failures make for far more
        # interesting traces/logs/dashboards to screenshot than a service
        # that never errors.
        self.simulated_failure_rate = float(os.getenv("SIMULATED_FAILURE_RATE", "0.1"))
        self.simulated_processing_ms = int(os.getenv("SIMULATED_PROCESSING_MS", "250"))


config = Config()