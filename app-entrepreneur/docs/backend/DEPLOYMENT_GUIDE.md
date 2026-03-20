# VernonEdu Entrepreneurship API — Deployment Guide

**Version:** 1.0.0
**Status:** Production-Ready
**Target Environments:** Development, Staging, Production

---

## 🎯 Deployment Overview

### Environments

| Env | Base URL | DB | Cache | Use Case |
|-----|----------|----|----|----------|
| **Local** | http://localhost:8080 | Docker Postgres | Docker Redis | Development |
| **Dev** | https://api-dev.vernonedu.local | Cloud DB | Cloud Redis | Feature testing |
| **Staging** | https://api-staging.vernonedu.local | Cloud DB | Cloud Redis | Pre-release testing |
| **Production** | https://api.vernonedu.local | Managed RDS | Managed ElastiCache | Live users |

---

## 🐳 Docker Deployment

### Local Development (Docker Compose)

**File:** `deployments/docker/docker-compose.yml`

```yaml
version: '3.9'

services:
  # PostgreSQL
  postgres:
    image: postgres:15-alpine
    container_name: vernonedu_postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: vernonedu_entrepreneurship
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./internal/database/migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis
  redis:
    image: redis:7-alpine
    container_name: vernonedu_redis
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # API Server
  api:
    build:
      context: ../..
      dockerfile: deployments/docker/Dockerfile
    container_name: vernonedu_api
    ports:
      - "8080:8080"
    environment:
      PORT: 8080
      ENV: development
      LOG_LEVEL: debug
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: vernonedu_entrepreneurship
      DB_MAX_CONNECTIONS: 25
      REDIS_HOST: redis
      REDIS_PORT: 6379
      JWT_SECRET: dev-secret-key-min-32-chars-long
      CORS_ALLOWED_ORIGINS: "http://localhost:3000,http://localhost:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ../../:/app
    command: go run cmd/server/main.go

volumes:
  postgres_data:
```

**File:** `deployments/docker/Dockerfile`

```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o api cmd/server/main.go

# Runtime stage
FROM alpine:3.19

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /app/api .

# Copy migrations
COPY --from=builder /app/internal/database/migrations ./migrations

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run
CMD ["./api"]
```

### Quick Start

```bash
# 1. Start stack
docker-compose -f deployments/docker/docker-compose.yml up -d

# 2. Check logs
docker-compose -f deployments/docker/docker-compose.yml logs -f api

# 3. Test health
curl http://localhost:8080/health

# 4. Stop
docker-compose -f deployments/docker/docker-compose.yml down
```

---

## ☁️ Cloud Deployment

### Kubernetes (Recommended for Production)

**File:** `deployments/k8s/deployment.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
  namespace: vernonedu
data:
  ENV: "production"
  LOG_LEVEL: "info"
  DB_MAX_CONNECTIONS: "50"
  CORS_ALLOWED_ORIGINS: "https://app.vernonedu.local"

---
apiVersion: v1
kind: Secret
metadata:
  name: api-secrets
  namespace: vernonedu
type: Opaque
stringData:
  JWT_SECRET: "your-production-secret-min-32-chars"
  DB_HOST: "rds-endpoint.amazonaws.com"
  DB_USER: "postgres"
  DB_PASSWORD: "your-secure-password"
  DB_NAME: "vernonedu_entrepreneurship"
  REDIS_HOST: "elasticache-endpoint.amazonaws.com"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vernonedu-api
  namespace: vernonedu
  labels:
    app: vernonedu-api
spec:
  replicas: 3  # High availability
  selector:
    matchLabels:
      app: vernonedu-api
  template:
    metadata:
      labels:
        app: vernonedu-api
    spec:
      containers:
      - name: api
        image: your-registry/vernonedu-api:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
        envFrom:
        - configMapRef:
            name: api-config
        - secretRef:
            name: api-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: vernonedu-api-service
  namespace: vernonedu
spec:
  type: LoadBalancer
  selector:
    app: vernonedu-api
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
```

### Deploy to Kubernetes

```bash
# 1. Create namespace
kubectl create namespace vernonedu

# 2. Create secrets
kubectl create secret generic api-secrets \
  --from-literal=JWT_SECRET='...' \
  --from-literal=DB_PASSWORD='...' \
  -n vernonedu

# 3. Apply manifests
kubectl apply -f deployments/k8s/

# 4. Check deployment
kubectl rollout status deployment/vernonedu-api -n vernonedu

# 5. Get service IP
kubectl get service vernonedu-api-service -n vernonedu
```

### Database Setup (AWS RDS)

```bash
# 1. Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier vernonedu-entrepreneurship \
  --db-instance-class db.t4g.micro \
  --engine postgres \
  --engine-version 15 \
  --master-username postgres \
  --master-user-password 'your-secure-password' \
  --allocated-storage 20 \
  --backup-retention-period 7 \
  --multi-az \
  --publicly-accessible false

# 2. Get endpoint
aws rds describe-db-instances \
  --db-instance-identifier vernonedu-entrepreneurship \
  --query 'DBInstances[0].Endpoint.Address'

# 3. Run migrations
PGHOST=<rds-endpoint> PGUSER=postgres PGPASSWORD=<password> \
  psql -d vernonedu_entrepreneurship < internal/database/migrations/*.sql
```

### Cache Setup (AWS ElastiCache)

```bash
# 1. Create Redis cluster
aws elasticache create-cache-cluster \
  --cache-cluster-id vernonedu-cache \
  --cache-node-type cache.t4g.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1

# 2. Get endpoint
aws elasticache describe-cache-clusters \
  --cache-cluster-id vernonedu-cache \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint'
```

---

## 🔄 CI/CD Pipeline (GitHub Actions)

**File:** `.github/workflows/deploy.yml`

```yaml
name: Deploy API

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/api

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-go@v4
      with:
        go-version: '1.22'

    - name: Run tests
      run: go test -v -race -coverprofile=coverage.out ./...

    - name: Check coverage
      run: |
        coverage=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
        if (( $(echo "$coverage < 70" | bc -l) )); then
          echo "Coverage $coverage% is below 70% threshold"
          exit 1
        fi

    - name: Run linter
      uses: golangci/golangci-lint-action@v3
      with:
        version: latest

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - uses: actions/checkout@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}

    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        file: ./deployments/docker/Dockerfile
        push: ${{ github.event_name != 'pull_request' }}
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
    - uses: actions/checkout@v3

    - name: Deploy to Kubernetes
      env:
        KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
      run: |
        mkdir -p $HOME/.kube
        echo "$KUBE_CONFIG" | base64 -d > $HOME/.kube/config
        chmod 600 $HOME/.kube/config

        # Update image in deployment
        kubectl set image deployment/vernonedu-api \
          api=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest \
          -n vernonedu

        # Wait for rollout
        kubectl rollout status deployment/vernonedu-api -n vernonedu
```

---

## 📋 Pre-Deployment Checklist

### Code Quality
- [ ] All tests pass (`go test -v`)
- [ ] Coverage ≥ 70% (`go tool cover`)
- [ ] No linter issues (`golangci-lint run`)
- [ ] No security issues (`gosec ./...`)

### Configuration
- [ ] All environment variables documented
- [ ] Secrets stored in secure vault
- [ ] CORS origins configured
- [ ] Rate limiting configured
- [ ] Log level set appropriately

### Database
- [ ] Migrations tested locally
- [ ] Backup strategy documented
- [ ] Connection pooling configured
- [ ] Indexes created
- [ ] Monitoring alerts setup

### Security
- [ ] HTTPS enabled
- [ ] JWT secret rotated
- [ ] Database credentials encrypted
- [ ] API keys not in code
- [ ] Security headers configured

### Performance
- [ ] Load testing completed
- [ ] Database query optimization done
- [ ] Caching strategy implemented
- [ ] CDN configured (if needed)

### Monitoring
- [ ] Logging setup (ELK/CloudWatch)
- [ ] APM instrumented
- [ ] Error tracking configured (Sentry)
- [ ] Alerts configured for:
  - High error rate
  - High latency
  - Database connection issues
  - Redis connection issues
  - Disk space

---

## 🚀 Deployment Steps

### 1. Local Testing
```bash
# Build locally
make build

# Run with Docker Compose
docker-compose -f deployments/docker/docker-compose.yml up

# Test endpoints
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@vernonedu.local","password":"password123"}'
```

### 2. Staging Deployment
```bash
# Push to registry
docker tag vernonedu-api:latest your-registry/vernonedu-api:staging
docker push your-registry/vernonedu-api:staging

# Deploy to staging K8s
kubectl set image deployment/vernonedu-api-staging \
  api=your-registry/vernonedu-api:staging \
  -n vernonedu-staging

# Smoke tests
./scripts/smoke-tests.sh https://api-staging.vernonedu.local
```

### 3. Production Deployment
```bash
# Tag with version
docker tag vernonedu-api:latest your-registry/vernonedu-api:v1.0.0
docker push your-registry/vernonedu-api:v1.0.0

# Create backup before deploy
aws rds create-db-snapshot \
  --db-instance-identifier vernonedu-entrepreneurship \
  --db-snapshot-identifier vernonedu-pre-deploy-v1.0.0

# Deploy to production
kubectl set image deployment/vernonedu-api \
  api=your-registry/vernonedu-api:v1.0.0 \
  -n vernonedu

# Monitor rollout
watch kubectl rollout status deployment/vernonedu-api -n vernonedu

# Health check
curl https://api.vernonedu.local/health
```

---

## 🔍 Post-Deployment Validation

```bash
# 1. Check all replicas running
kubectl get pods -n vernonedu

# 2. Check service endpoints
kubectl get endpoints vernonedu-api-service -n vernonedu

# 3. Test auth
curl -X POST https://api.vernonedu.local/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@vernonedu.local","password":"password123"}'

# 4. Test business CRUD
curl -H "Authorization: Bearer $TOKEN" \
  https://api.vernonedu.local/v1/businesses

# 5. Check logs
kubectl logs -f deployment/vernonedu-api -n vernonedu
```

---

## 🛠️ Troubleshooting

### Pod Crash Loop
```bash
# Check logs
kubectl logs vernonedu-api-xxx -n vernonedu

# Common causes:
# - Missing environment variables
# - Database not reachable
# - Invalid config
```

### Database Connection Issues
```bash
# Test connectivity from pod
kubectl exec -it vernonedu-api-xxx -n vernonedu -- \
  psql -h $DB_HOST -U $DB_USER -d vernonedu_entrepreneurship

# Check RDS security group
aws ec2 describe-security-groups --filter Name=group-id,Values=sg-xxxxx
```

### Rate Limiting Issues
```bash
# Test Redis connectivity
kubectl exec -it vernonedu-api-xxx -n vernonedu -- \
  redis-cli -h $REDIS_HOST ping

# Check Redis memory
redis-cli info memory
```

---

## 📊 Monitoring & Observability

### Logging (CloudWatch / ELK)
```
Every request logs:
- Timestamp
- Request ID
- User ID
- Method + Path
- Status code
- Response time
- Errors (if any)
```

### Metrics (Prometheus/CloudWatch)
```
Tracked:
- HTTP request count (per endpoint)
- HTTP latency (per endpoint)
- Database query count
- Database query latency
- Error count (per error code)
- Redis cache hit/miss rate
```

### Alerts
```
Alert on:
- Error rate > 1%
- P99 latency > 1s
- Database connections > 80%
- Redis memory > 80%
- Disk usage > 85%
```

---

## 🔄 Rollback Procedure

```bash
# If something goes wrong, revert to previous image
kubectl set image deployment/vernonedu-api \
  api=your-registry/vernonedu-api:v0.9.9 \
  -n vernonedu

# Wait for rollout
kubectl rollout status deployment/vernonedu-api -n vernonedu

# If database is corrupted, restore from backup
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier vernonedu-entrepreneurship-restored \
  --db-snapshot-identifier vernonedu-pre-deploy-v1.0.0
```

---

## ✅ Deployment Checklist

- [ ] Code reviewed and approved
- [ ] Tests passing with 70%+ coverage
- [ ] Linter clean
- [ ] Security scan clean
- [ ] Staging deployment successful
- [ ] Smoke tests passed
- [ ] Database backup created
- [ ] Monitoring alerts tested
- [ ] Rollback plan documented
- [ ] Team notified
- [ ] Production deployment completed
- [ ] Health checks passing
- [ ] Error rate normal
- [ ] Performance metrics normal
- [ ] Logs flowing to monitoring system

---

**Ready to deploy! 🚀**
