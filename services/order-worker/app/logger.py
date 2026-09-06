import json
import logging
import sys

from opentelemetry import trace


class JSONFormatter(logging.Formatter):
    """Emits one JSON object per log line so Fluent Bit can parse fields
    directly instead of regexing plain text — same contract api-gateway uses."""

    def __init__(self, service_name: str):
        super().__init__()
        self.service_name = service_name

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname.lower(),
            "service": self.service_name,
            "message": record.getMessage(),
        }

        # Attach trace_id/span_id from the active span, if any — this is
        # the field Kibana and Jaeger share for correlation.
        span = trace.get_current_span()
        ctx = span.get_span_context()
        if ctx.is_valid:
            payload["trace_id"] = format(ctx.trace_id, "032x")
            payload["span_id"] = format(ctx.span_id, "016x")

        # Any extra kwargs passed via logger.info("msg", extra={...})
        for key, value in getattr(record, "extra_fields", {}).items():
            payload[key] = value

        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)

        return json.dumps(payload)


def get_logger(service_name: str, level: str) -> logging.Logger:
    logger = logging.getLogger(service_name)
    logger.setLevel(getattr(logging, level.upper(), logging.INFO))

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter(service_name))
    logger.handlers = [handler]
    logger.propagate = False
    return logger


def log_with_fields(logger: logging.Logger, level: str, message: str, **fields):
    """Convenience wrapper: logger.info("order processed", order_id=x, status=y)"""
    getattr(logger, level)(message, extra={"extra_fields": fields})