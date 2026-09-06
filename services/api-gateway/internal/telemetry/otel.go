package telemetry

import (
	"context"
	"fmt"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

// InitTracer wires up a TracerProvider that batches spans and ships them to
// the OTel Collector over OTLP/gRPC. The collector then fans out to Jaeger
// (and later, other backends) without api-gateway needing to know about that.
//
// Returns a shutdown func — callers MUST defer it so buffered spans flush
// before the process exits.
func InitTracer(ctx context.Context, serviceName, collectorEndpoint string) (func(context.Context) error, error) {
	exporter, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithEndpoint(collectorEndpoint),
		otlptracegrpc.WithInsecure(), // fine inside the cluster network; not for public internet
	)
	if err != nil {
		return nil, fmt.Errorf("creating otlp exporter: %w", err)
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceName(serviceName),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("creating otel resource: %w", err)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)

	otel.SetTracerProvider(tp)
	// W3C trace context propagation is what lets the trace continue across
	// the Kafka hop into order-worker — we inject these headers manually
	// when producing messages.
	otel.SetTextMapPropagator(propagation.TraceContext{})

	return tp.Shutdown, nil
}