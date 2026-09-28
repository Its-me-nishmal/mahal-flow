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

RUN apk add --no-cache ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /app/server /app/server

# Expose Render default port (overrideable via PORT env var)
EXPOSE 8080

CMD ["/app/server"]
