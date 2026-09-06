package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"

	"github.com/orderly/api-gateway/internal/config"
	"github.com/orderly/api-gateway/internal/handlers"
	"github.com/orderly/api-gateway/internal/kafka"
	"github.com/orderly/api-gateway/internal/logger"
	"github.com/orderly/api-gateway/internal/telemetry"
)

func main() {
	cfg := config.Load()
	log := logger.New(cfg.ServiceName, cfg.LogLevel)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// --- Tracing ---
	shutdownTracer, err := telemetry.InitTracer(ctx, cfg.ServiceName, cfg.OTelCollectorEndpoint)
	if err != nil {
		log.Error("failed to init tracer", "error", err.Error())
		os.Exit(1)
	}
	defer func() {
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := shutdownTracer(shutdownCtx); err != nil {
			log.Error("tracer shutdown error", "error", err.Error())
		}
	}()

	// --- Kafka producer ---
	producer := kafka.NewProducer(cfg.KafkaBrokers, cfg.KafkaTopicOrders)
	defer producer.Close()

	orderHandler := handlers.NewOrderHandler(producer, log)

	// --- Routes ---
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", handlers.Healthz)
	mux.Handle("GET /metrics", promhttp.Handler())
	mux.HandleFunc("POST /orders", orderHandler.CreateOrder)
	mux.HandleFunc("GET /orders/{id}", orderHandler.GetOrder)

	// otelhttp wraps every request in a span automatically, named after the
	// route pattern, and propagates trace context from incoming headers.
	instrumentedMux := otelhttp.NewHandler(mux, cfg.ServiceName)

	srv := &http.Server{
		Addr:         ":" + cfg.HTTPPort,
		Handler:      instrumentedMux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	go func() {
		log.Info("api-gateway listening", "port", cfg.HTTPPort)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error("server error", "error", err.Error())
			os.Exit(1)
		}
	}()

	<-ctx.Done()
	log.Info("shutdown signal received, draining connections")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Error("graceful shutdown failed", "error", err.Error())
	}
}