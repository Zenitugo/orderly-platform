import signal
import threading

from app.config import config
from app.consumer import OrderConsumer
from app.db import Database
from app.logger import get_logger, log_with_fields
from app.metrics import start_metrics_server
from app.producer import CompletedEventProducer
from app.telemetry import init_tracer


def main():
    logger = get_logger(config.service_name, config.log_level)

    tracer, provider = init_tracer(config.service_name, config.otel_collector_endpoint)

    db = Database(config.postgres_dsn)
    db.init_schema()
    log_with_fields(logger, "info", "database schema ready")

    start_metrics_server(config.metrics_port)
    log_with_fields(logger, "info", "metrics server started", port=config.metrics_port)

    completed_producer = CompletedEventProducer(
        config.kafka_brokers, config.kafka_topic_orders_completed
    )

    consumer = OrderConsumer(db, completed_producer, tracer, logger)

    stop_flag = threading.Event()

    def handle_signal(signum, frame):
        log_with_fields(logger, "info", "shutdown signal received", signal=signum)
        stop_flag.set()

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    try:
        consumer.run(stop_flag)
    finally:
        completed_producer.flush()
        db.close()
        provider.shutdown()
        log_with_fields(logger, "info", "order-worker stopped cleanly")


if __name__ == "__main__":
    main()