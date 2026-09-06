package handlers

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus"

	"github.com/orderly/api-gateway/internal/kafka"
	"github.com/orderly/api-gateway/internal/logger"
	"github.com/orderly/api-gateway/internal/models"
)

var (
	ordersCreatedTotal = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "orders_created_total",
		Help: "Total number of orders successfully accepted.",
	})
	ordersRejectedTotal = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "orders_rejected_total",
		Help: "Total number of order requests rejected due to validation or downstream errors.",
	})
)

func init() {
	prometheus.MustRegister(ordersCreatedTotal, ordersRejectedTotal)
}

// OrderHandler holds dependencies needed to handle order-related requests.
type OrderHandler struct {
	producer *kafka.Producer
	log      *slog.Logger
}

func NewOrderHandler(producer *kafka.Producer, log *slog.Logger) *OrderHandler {
	return &OrderHandler{producer: producer, log: log}
}

// CreateOrder handles POST /orders. It validates the request, publishes an
// OrderCreatedEvent to Kafka (with trace context attached), and returns 202
// Accepted — this is an async flow, order-worker does the real processing.
func (h *OrderHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	log := logger.FromContext(ctx, h.log)

	var req models.CreateOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		ordersRejectedTotal.Inc()
		log.Warn("failed to decode request body", "error", err.Error())
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}

	if problems := req.Validate(); len(problems) > 0 {
		ordersRejectedTotal.Inc()
		log.Info("order rejected: validation failed", "problems", problems)
		writeError(w, http.StatusUnprocessableEntity, strings.Join(problems, "; "))
		return
	}

	orderID := uuid.New().String()
	event := models.OrderCreatedEvent{
		OrderID:    orderID,
		CustomerID: req.CustomerID,
		Item:       req.Item,
		Quantity:   req.Quantity,
		Status:     models.StatusPending,
		CreatedAt:  time.Now().UTC(),
	}

	if err := h.producer.Publish(ctx, orderID, event); err != nil {
		ordersRejectedTotal.Inc()
		log.Error("failed to publish order event", "order_id", orderID, "error", err.Error())
		writeError(w, http.StatusInternalServerError, "failed to accept order")
		return
	}

	ordersCreatedTotal.Inc()
	log.Info("order accepted", "order_id", orderID, "customer_id", req.CustomerID)

	writeJSON(w, http.StatusAccepted, models.CreateOrderResponse{
		OrderID: orderID,
		Status:  models.StatusPending,
	})
}

// GetOrder handles GET /orders/{id}. api-gateway doesn't own order state —
// order-worker does — so for now this returns a clear "not here" response.
// Once order-worker exposes a query API, this will proxy to it.
func (h *OrderHandler) GetOrder(w http.ResponseWriter, r *http.Request) {
	orderID := r.PathValue("id")
	writeJSON(w, http.StatusNotImplemented, map[string]string{
		"order_id": orderID,
		"message":  "order status queries are served by order-worker; not wired up yet",
	})
}

// Healthz is a liveness probe: is the process running at all.
func Healthz(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}