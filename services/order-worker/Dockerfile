FROM python:3.12-slim AS builder

# confluent-kafka needs librdkafka's headers to build its C extension
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    librdkafka-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- runtime stage ---
FROM python:3.12-slim

# librdkafka's runtime .so is still needed even though the C headers aren't
RUN apt-get update && apt-get install -y --no-install-recommends \
    librdkafka1 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 appuser

COPY --from=builder /install /usr/local

WORKDIR /app
COPY app/ ./app/
COPY main.py .

USER appuser
EXPOSE 9100

CMD ["python", "main.py"]