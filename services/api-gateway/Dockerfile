# --- build stage ---
FROM golang:1.22-alpine AS builder

WORKDIR /src

# Cache module downloads separately from source changes
COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/api-gateway .

# --- runtime stage ---
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app
COPY --from=builder /out/api-gateway .

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/app/api-gateway"]