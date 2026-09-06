from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass
class OrderCreatedEvent:
    """Matches the JSON shape api-gateway publishes to orders.created."""
    order_id: str
    customer_id: str
    item: str
    quantity: int
    status: str
    created_at: str

    @staticmethod
    def from_dict(d: dict) -> "OrderCreatedEvent":
        return OrderCreatedEvent(
            order_id=d["order_id"],
            customer_id=d["customer_id"],
            item=d["item"],
            quantity=d["quantity"],
            status=d["status"],
            created_at=d["created_at"],
        )


@dataclass
class OrderCompletedEvent:
    """Published to orders.completed. status is either 'completed' or
    'failed' — notifier decides how to react based on that field."""
    order_id: str
    customer_id: str
    status: str
    failure_reason: str | None
    completed_at: str

    def to_dict(self) -> dict:
        return {
            "order_id": self.order_id,
            "customer_id": self.customer_id,
            "status": self.status,
            "failure_reason": self.failure_reason,
            "completed_at": self.completed_at,
        }


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()