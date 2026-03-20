.PHONY: build dev test test-race lint migrate-up migrate-down migrate-create infra-up infra-down help tidy

SERVICE=entrepreneurship-api
MAIN=./cmd/api
BIN=./bin/$(SERVICE)

# Build variables
LD_FLAGS=-ldflags "-X main.Version=$(shell git describe --tags --always --dirty)"

help:
	@echo "Available commands:"
	@echo "  make build              - Build the application"
	@echo "  make dev                - Run with hot reload (requires air)"
	@echo "  make test               - Run unit tests"
	@echo "  make test-race          - Run tests with race detector"
	@echo "  make test-integration   - Run integration tests"
	@echo "  make lint               - Run linter"
	@echo "  make migrate-up         - Run pending migrations"
	@echo "  make migrate-down       - Rollback last migration"
	@echo "  make migrate-create     - Create new migration (name=<migration_name>)"
	@echo "  make infra-up           - Start infrastructure (Docker)"
	@echo "  make infra-down         - Stop infrastructure (Docker)"
	@echo "  make tidy               - Tidy go modules"

build:
	@echo "Building $(SERVICE)..."
	@mkdir -p $(dir $(BIN))
	@go build $(LD_FLAGS) -o $(BIN) $(MAIN)
	@echo "Build complete: $(BIN)"

dev:
	@echo "Starting development server..."
	@air

test:
	@echo "Running unit tests..."
	@go test ./internal/... ./pkg/... -v -timeout 30s -race

test-race:
	@echo "Running tests with race detector..."
	@go test -race ./... -timeout 60s -v

test-integration:
	@echo "Running integration tests..."
	@go test ./tests/integration/... -v -timeout 120s -tags integration

lint:
	@echo "Running linter..."
	@golangci-lint run ./...

migrate-up:
	@echo "Running migrations..."
	@migrate -path migrations -database "$(DATABASE_URL)" up

migrate-down:
	@echo "Rollback last migration..."
	@migrate -path migrations -database "$(DATABASE_URL)" down 1

migrate-create:
	@if [ -z "$(name)" ]; then \
		echo "Error: Please provide migration name (name=<migration_name>)"; \
		exit 1; \
	fi
	@migrate create -ext sql -dir migrations -seq $(name)

infra-up:
	@echo "Starting infrastructure..."
	@docker compose up -d
	@echo "Infrastructure started. Waiting for services to be ready..."
	@sleep 10
	@echo "Services are ready:"
	@echo "  - PostgreSQL: localhost:5432"
	@echo "  - Redis: localhost:6379"
	@echo "  - NATS: localhost:4222"
	@echo "  - Jaeger: http://localhost:16686"
	@echo "  - Prometheus: http://localhost:9090"

infra-down:
	@echo "Stopping infrastructure..."
	@docker compose down

tidy:
	@echo "Tidying Go modules..."
	@go mod tidy

.DEFAULT_GOAL := help
