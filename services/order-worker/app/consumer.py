import json
import random
import time

from confluent_kafka import Consumer, KafkaError
from opentelemetry import propagate
from opentelemetry.propagators.textmap import Getter

from app.config import config
from app.logger import log_with_fields
from app.metrics import (
    kafka_consume_errors_total,
    order_processing_seconds,
    orders_processed_total,
)
from app.models import OrderCompletedEvent, OrderCreatedEvent, now_iso


class _HeaderGetter(Getter):
    """Reads traceparent back out of Kafka message headers so the span
    started here becomes a child of the span api-gateway created — this is
    what makes it one continuous trace across the queue instead of two
    disconnected ones."""

    def get(self, carrier, key):
        if carrier is None:
            return None
        for k, v in carrier:
            if k == key:
                return [v.decode("utf-8") if isinstance(v, bytes) else v]
        return None

    def keys(self, carrier):
        return [k for k, _ in carrier] if carrier else []


_getter = _HeaderGetter()


class OrderConsumer:
    def __init__(self, db, completed_producer, tracer, logger):
        self.db = db
        self.completed_producer = completed_producer
        self.tracer = tracer
        self.logger = logger

        self.consumer = Consumer({
            "bootstrap.servers": config.kafka_brokers,
            "group.id": config.kafka_consumer_group,
            "auto.offset.reset": "earliest",
            "enable.auto.commit": True,
        })
        self.consumer.subscribe([config.kafka_topic_orders_created])

    def run(self, stop_flag):
        log_with_fields(self.logger, "info", "order-worker consuming",
                         topic=config.kafka_topic_orders_created)

        while not stop_flag.is_set():
            msg = self.consumer.poll(timeout=1.0)
            if msg is None:
                continue
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    continue
                kafka_consume_errors_total.inc()
                log_with_fields(self.logger, "error", "kafka consume error",
                                 error=str(msg.error()))
                continue

            self._handle_message(msg)

        self.consumer.close()

    def _handle_message(self, msg):
        # Extract the trace context api-gateway attached to this message's
        # headers, then start our span as a child of it.
        ctx = propagate.extract(msg.headers(), getter=_getter)

        with self.tracer.start_as_current_span("process_order", context=ctx) as span:
            start = time.time()
            try:
                payload = json.loads(msg.value())
                event = OrderCreatedEvent.from_dict(payload)
                span.set_attribute("order.id", event.order_id)
                span.set_attribute("order.customer_id", event.customer_id)

                self._process_order(event)

            except Exception as exc: # noqa: BLE001
                span.record_exception(exc)
                kafka_consume_errors_total.inc()
                log_with_fields(self.logger, "error", "failed to handle message",
                                 error=str(exc))
            finally:
                order_processing_seconds.observe(time.time() - start)

    def _process_order(self, event: OrderCreatedEvent):
        # Simulated work — a real service would call inventory, payment, etc.
        # This is where the tracer becomes useful: this sleep + the DB write
        # below both show up as child spans/timings in Jaeger.
        time.sleep(config.simulated_processing_ms / 1000)

        failed = random.random() < config.simulated_failure_rate
        status = "failed" if failed else "completed"
        failure_reason = "simulated downstream failure" if failed else None

        self.db.upsert_order(
            order_id=event.order_id,
            customer_id=event.customer_id,
            item=event.item,
            quantity=event.quantity,
            status=status,
            created_at=event.created_at,
            failure_reason=failure_reason,
        )

        completed_event = OrderCompletedEvent(
            order_id=event.order_id,
            customer_id=event.customer_id,
            status=status,
            failure_reason=failure_reason,
            completed_at=now_iso(),
        )
        self.completed_producer.publish(event.order_id, completed_event.to_dict())

        orders_processed_total.labels(status=status).inc()
        log_with_fields(
            self.logger, "info" if not failed else "warning",
            "order processed",
            order_id=event.order_id, status=status, failure_reason=failure_reason,
        )