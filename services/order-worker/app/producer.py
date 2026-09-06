import json

from confluent_kafka import Producer
from opentelemetry import propagate
from opentelemetry.propagators.textmap import Setter


class _HeaderSetter(Setter):
    """Lets the otel propagator write traceparent into Kafka message headers,
    same pattern api-gateway uses, so notifier can continue the same trace."""

    def set(self, carrier: list, key: str, value: str):
        carrier.append((key, value.encode("utf-8")))


_setter = _HeaderSetter()


class CompletedEventProducer:
    def __init__(self, brokers: str, topic: str):
        self.producer = Producer({"bootstrap.servers": brokers})
        self.topic = topic

    def publish(self, key: str, event: dict):
        headers: list = []
        propagate.inject(headers, setter=_setter)

        self.producer.produce(
            self.topic,
            key=key.encode("utf-8"),
            value=json.dumps(event).encode("utf-8"),
            headers=headers,
        )
        self.producer.poll(0)  # trigger delivery callbacks without blocking

    def flush(self, timeout: float = 5.0):
        self.producer.flush(timeout)