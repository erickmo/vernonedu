BACKEND_DIR  := backend
FRONTEND_DIR := frontend
MIGRATIONS   := $(BACKEND_DIR)/migrations
DB_URL       := postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable

.PHONY: all docker-up docker-down migrate-up migrate-down \
        api worker fe-install fe-dev lint test clean

all: docker-up migrate-up

docker-up:
	docker compose up -d
	@echo "Waiting for postgres..."
	@until docker exec vernonedu_postgres pg_isready -U vernonedu > /dev/null 2>&1; do sleep 1; done
	@echo "Postgres ready."

docker-down:
	docker compose down

docker-reset:
	docker compose down -v && docker compose up -d

migrate-up:
	migrate -path $(MIGRATIONS) -database "$(DB_URL)" up

migrate-down:
	migrate -path $(MIGRATIONS) -database "$(DB_URL)" down 1

migrate-down-all:
	migrate -path $(MIGRATIONS) -database "$(DB_URL)" down -all

migrate-create:
	@read -p "Name: " name; migrate create -ext sql -dir $(MIGRATIONS) -seq $$name

generate:
	cd $(BACKEND_DIR) && sqlc generate

api:
	cd $(BACKEND_DIR) && go run ./cmd/api

worker:
	cd $(BACKEND_DIR) && go run ./cmd/worker

test:
	cd $(BACKEND_DIR) && go test -race -cover ./...

test-integration:
	cd $(BACKEND_DIR) && go test -tags=integration -count=1 -race -p=1 ./...

lint:
	cd $(BACKEND_DIR) && golangci-lint run ./...

fe-install:
	cd $(FRONTEND_DIR) && npm install

fe-dev:
	cd $(FRONTEND_DIR) && npm run dev

fe-build:
	cd $(FRONTEND_DIR) && npm run build

clean:
	rm -rf backend/bin frontend/dist
