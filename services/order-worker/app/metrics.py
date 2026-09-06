from prometheus_client import Counter, Histogram, start_http_server

orders_processed_total = Counter(
    "orders_processed_total", "Total orders processed, by outcome.", ["status"]
)

order_processing_seconds = Histogram(
    "order_processing_seconds", "Time spent processing a single order end to end."
)

kafka_consume_errors_total = Counter(
    "kafka_consume_errors_total", "Total errors encountered while consuming from Kafka."
)


def start_metrics_server(port: int):
    start_http_server(port)