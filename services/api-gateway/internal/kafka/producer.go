package kafka

import (
	"context"
	"encoding/json"
	"fmt"

	kafkago "github.com/segmentio/kafka-go"
	"github.com/prometheus/client_golang/prometheus"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"
)

// headerCarrier lets otel's propagator write W3C traceparent info directly
// into Kafka message headers, so order-worker can pick up the same trace
// when it consumes the message.
type headerCarrier struct {
	headers *[]kafkago.Header
}

func (c headerCarrier) Get(key string) string { return "" } // not needed for injection
func (c headerCarrier) Set(key, value string) {
	*c.headers = append(*c.headers, kafkago.Header{Key: key, Value: []byte(value)})
}
func (c headerCarrier) Keys() []string { return nil }

var (
	messagesProduced = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "kafka_messages_produced_total",
			Help: "Total messages successfully produced, by topic.",
		},
		[]string{"topic"},
	)
	produceFailures = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "kafka_produce_failures_total",
			Help: "Total failed produce attempts, by topic.",
		},
		[]string{"topic"},
	)
)

func init() {
	prometheus.MustRegister(messagesProduced, produceFailures)
}

// Producer wraps a kafka-go Writer for a single topic.
type Producer struct {
	writer *kafkago.Writer
	topic  string
}

func NewProducer(brokers []string, topic string) *Producer {
	return &Producer{
		writer: &kafkago.Writer{
			Addr:                   kafkago.TCP(brokers...),
			Topic:                  topic,
			Balancer:               &kafkago.LeastBytes{},
			AllowAutoTopicCreation: true,
		},
		topic: topic,
	}
}

// Publish serializes v as JSON, injects the current trace context into
// Kafka headers, and produces the message keyed by key (e.g. order ID) so
// all events for the same order land on the same partition, in order.
func (p *Producer) Publish(ctx context.Context, key string, v interface{}) error {
	payload, err := json.Marshal(v)
	if err != nil {
		produceFailures.WithLabelValues(p.topic).Inc()
		return fmt.Errorf("marshaling message: %w", err)
	}

	var headers []kafkago.Header
	otel.GetTextMapPropagator().Inject(ctx, headerCarrier{headers: &headers})

	msg := kafkago.Message{
		Key:     []byte(key),
		Value:   payload,
		Headers: headers,
	}

	if err := p.writer.WriteMessages(ctx, msg); err != nil {
		produceFailures.WithLabelValues(p.topic).Inc()
		return fmt.Errorf("writing kafka message: %w", err)
	}

	messagesProduced.WithLabelValues(p.topic).Inc()
	return nil
}

func (p *Producer) Close() error {
	return p.writer.Close()
}

var _ = propagation.TraceContext{} // keep import if unused elsewhere