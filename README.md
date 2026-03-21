# VernonEdu

Monorepo platform pendidikan VernonEdu — entrepreneurship, kurikulum, dan manajemen kelas.

## Projects

| Folder | Stack | Deskripsi | Port Dev |
|--------|-------|-----------|----------|
| `api/` | Go + Chi + CQRS | Backend REST API | `:8081` |
| `app-entrepreneur/` | Flutter Web PWA | Aplikasi siswa (entrepreneurship) | `:3000` |
| `app-dashboard/` | Flutter Web | Dashboard admin & instruktur | `:3001` |
| `app-blockcoding/` | Flutter Web | Sub-app block coding | `:3002` |
| `app-mentors/` | Flutter Mobile (Android/iOS) | Aplikasi mentor, fasilitator & course owner | — |
| `app-student/` | Flutter Mobile (Android/iOS) | Aplikasi siswa (mobile) | — |
| `app-mcb-junior/` | Flutter | MCB Junior app | — |
| `app-website/` | Web | Website promosi VernonEdu | — |

## Quick Start

### 1. Start Infrastructure

```bash
cd api
make infra-up        # Start PostgreSQL, Redis, NATS, Jaeger, Prometheus
make migrate-up      # Jalankan database migrations
```

### 2. API

```bash
cd api
make dev             # Hot reload development server (port 8081)
```

### 3. App Entrepreneur (Web)

```bash
cd app-entrepreneur
make get             # Install dependencies
make run-dev         # Start app (Chrome, connect ke localhost:8081)
```

### 4. App Dashboard (Web)

```bash
cd app-dashboard
make get             # Install dependencies
make run-dev         # Start dashboard (Chrome, port 3001)
```

### 5. App Mentors (Mobile)

```bash
cd app-mentors
flutter pub get
flutter run --dart-define=BASE_URL=http://localhost:8081/api/v1
```

### 6. App Student (Mobile)

```bash
cd app-student
flutter pub get
flutter run --dart-define=BASE_URL=http://localhost:8081/api/v1
```

## Dokumentasi Developer

| Dokumen | Deskripsi |
|---------|-----------|
| [Developer Guide](docs/DEVELOPER_GUIDE.md) | Panduan lengkap untuk developer |
| [API Reference](docs/API_REFERENCE.md) | Referensi endpoint API |
| [Architecture](docs/ARCHITECTURE.md) | Arsitektur sistem |
| [Contributing Guide](docs/CONTRIBUTING.md) | Cara berkontribusi & membuat fitur baru |
| [Environment Setup](docs/ENVIRONMENT_SETUP.md) | Setup environment & troubleshooting |

## Service Monitoring (Lokal)

| Service | URL |
|---------|-----|
| API | http://localhost:8081 |
| Jaeger (Tracing) | http://localhost:16686 |
| Prometheus (Metrics) | http://localhost:9090 |
| App Entrepreneur | http://localhost:3000 |
| App Dashboard | http://localhost:3001 |

---

**Last Updated:** Maret 2026
