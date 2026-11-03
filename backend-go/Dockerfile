# Multi-stage Docker build for MahalFlow Go Backend
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install build dependencies, CA certs for TLS to Atlas, and tzdata
RUN apk add --no-cache ca-certificates tzdata git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Compile static binary
RUN CGO_ENABLED=0 GOOS=linux go build -tags netgo -ldflags="-s -w" -o /app/server ./cmd/api

# Final minimal runner stage
FROM alpine:3.20

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S app && adduser -S -G app -H -s /sbin/nologin app

# Copy binary from builder
COPY --from=builder /app/server /app/server

# Run unprivileged
USER app

# Expose Render default port (overrideable via PORT env var)
EXPOSE 8080

# /health pings MongoDB and returns 503 when it is unreachable
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget -q -O /dev/null "http://127.0.0.1:${PORT:-8080}/health" || exit 1

CMD ["/app/server"]
