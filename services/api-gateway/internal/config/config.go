package config

import (
	"os"
	"strings"
)

// Config holds all runtime configuration for api-gateway, loaded from env vars.
// Keeping this centralized means every other package just imports Config
// instead of calling os.Getenv scattered everywhere.
type Config struct {
	ServiceName        string
	HTTPPort            string
	LogLevel            string
	KafkaBrokers        []string
	KafkaTopicOrders    string
	OTelCollectorEndpoint string
}

func Load() Config {
	return Config{
		ServiceName:           getEnv("SERVICE_NAME", "api-gateway"),
		HTTPPort:               getEnv("HTTP_PORT", "8080"),
		LogLevel:               getEnv("LOG_LEVEL", "info"),
		KafkaBrokers:           strings.Split(getEnv("KAFKA_BROKERS", "kafka:9092"), ","),
		KafkaTopicOrders:       getEnv("KAFKA_TOPIC_ORDERS_CREATED", "orders.created"),
		OTelCollectorEndpoint:  getEnv("OTEL_EXPORTER_OTLP_ENDPOINT", "otel-collector:4317"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}