package models

import "time"

// OrderStatus tracks where an order is in its lifecycle.
// api-gateway only ever sets "pending" — order-worker owns every
// transition after that.
type OrderStatus string

const (
	StatusPending OrderStatus = "pending"
)

// CreateOrderRequest is the JSON body accepted by POST /orders.
type CreateOrderRequest struct {
	CustomerID string `json:"customer_id"`
	Item       string `json:"item"`
	Quantity   int    `json:"quantity"`
}

func (r CreateOrderRequest) Validate() []string {
	var problems []string
	if r.CustomerID == "" {
		problems = append(problems, "customer_id is required")
	}
	if r.Item == "" {
		problems = append(problems, "item is required")
	}
	if r.Quantity <= 0 {
		problems = append(problems, "quantity must be greater than 0")
	}
	return problems
}

// OrderCreatedEvent is what gets published to the orders.created Kafka
// topic. order-worker consumes exactly this shape.
type OrderCreatedEvent struct {
	OrderID    string      `json:"order_id"`
	CustomerID string      `json:"customer_id"`
	Item       string      `json:"item"`
	Quantity   int         `json:"quantity"`
	Status     OrderStatus `json:"status"`
	CreatedAt  time.Time   `json:"created_at"`
}

// CreateOrderResponse is returned to the caller of POST /orders.
type CreateOrderResponse struct {
	OrderID string      `json:"order_id"`
	Status  OrderStatus `json:"status"`
}