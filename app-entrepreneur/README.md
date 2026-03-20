# VernonEdu Entrepreneurship App

Flutter Web PWA untuk siswa entrepreneurship VernonEdu — panduan terpadu dari belajar ilmu bisnis hingga mengelola operasional, finance, dan growth bisnis.

## 🚀 Quick Start

```bash
# Install dependencies
flutter pub get

# Run di Chrome
make run

# Run dengan dev API
make run-dev

# Build web release
make build-web
```

## 📱 Platform
- **Web PWA**: Install di home screen, bisa offline (dengan caching)
- **Browser Support**: Chrome, Safari, Firefox, Edge (latest 2 versions)
- **Responsive**: Mobile, Tablet, Desktop

## 🏗️ Architecture

Clean Architecture dengan struktur:
```
lib/features/
├── [feature_name]/
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── pages/
│       ├── widgets/
│       ├── bloc/ atau cubit/
│       └── [feature]_state.dart
```

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3.41.4, Google Fonts (Inter) |
| State | BLoC / Cubit |
| Navigation | go_router |
| Network | Dio |
| DI | get_it |
| Serialization | freezed v3 |
| Language | Dart 3.11.1 |

## ✨ Features

### Business Ideation ✅
Fitur untuk ideation dan planning bisnis dengan canvas-based worksheets:

- **Business Model Canvas (BMC)** — 9 building blocks untuk model bisnis
- **Value Proposition Canvas (VPC)** — pemetaan value vs customer needs
- **Design Thinking** — framework 5 tahap: Empathize, Define, Ideate, Prototype, Test
- **PESTEL Analysis** — analisis faktor eksternal (Political, Economic, Social, Technological, Environmental, Legal)
- **Flywheel Marketing** — strategi marketing berkelanjutan (Attract, Engage, Delight, Friction, Force)

**Fitur Canvas:**
- 📝 Sticky notes yang bisa diedit inline
- 💬 Expandable note section per item
- ➕ Tombol add/delete item dengan ✕
- 🔗 Cross-linking antar section (BMC) dengan click-to-scroll
- 📱 Responsive layout (desktop/tablet/mobile)
- 🎨 Visual hierarchy dengan warna per section

### Learning Module (In Progress)
Modul pembelajaran bisnis terstruktur

### Business Launchpad (Planned)
Tools untuk meluncurkan bisnis

### Business Operation (Planned)
Manajemen operasional bisnis

### Business Administration (Planned)
Administrasi bisnis

### Marketing & Branding (Planned)
Perencanaan marketing dan branding

### HR Management (Planned)
Manajemen human resource

### Finance & Reporting (Planned)
Manajemen keuangan dan laporan

## 📂 Project Structure

```
vernonedu_entrepreneurship_app/
├── lib/
│   ├── core/
│   │   ├── constants/     # app_colors, app_dimensions, app_strings
│   │   ├── failures/      # Error handling
│   │   └── utils/         # Helper functions
│   ├── features/
│   │   ├── business_ideation/  # ✅ Canvas-based worksheet
│   │   ├── learning/
│   │   ├── launchpad/
│   │   └── ...
│   ├── config/
│   │   └── routes/        # go_router configuration
│   └── main.dart
├── test/
├── pubspec.yaml
├── CLAUDE.md              # AI development guidelines
└── README.md              # This file
```

## 🎯 Development Guidelines

**Penting:** Baca `CLAUDE.md` sebelum mulai coding!

### Coding Standards
- ✅ SEMUA code ditulis oleh AI — gunakan `flutter-coding-standard` skill
- ✅ Widget > 50 baris → pecah ke sub-widget
- ❌ JANGAN business logic di build()
- ❌ JANGAN hardcode string/color/dimension
- ✅ Repository return `Either<Failure, T>`
- ✅ Handle semua state: loading/success/error/empty

### Commands
```bash
make run          # Run di Chrome
make run-dev      # Run dengan dev API
make test         # Run tests
make gen          # Build runner (code generation)
make analyze      # Flutter analyze
make build-web    # Build web release (PWA)
```

## 🔒 Security & Best Practices

- ❌ JANGAN push langsung ke main/master
- ❌ JANGAN hardcode URL atau API key
- ❌ JANGAN gunakan flutter_secure_storage (web tidak support → pakai shared_preferences)
- ✅ Gunakan environment variables untuk config
- ✅ Always validate user input di system boundaries

## 📚 Documentation

- **PRD**: `docs/requirements/prd-vernonedu-entrepreneurship.md`
- **Features**: `docs/FEATURES.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **Widget Guide**: Individual widget files dengan dokumentasi inline

## 🐛 Troubleshooting

### Build Cache Issues
```bash
flutter clean
flutter pub get
make run
```

### Port Conflict
Jika localhost:51540 sudah terpakai:
```bash
flutter run -d chrome --web-port 8080
```

### Analyzer Issues
```bash
flutter analyze --no-pub --skip-web-plugin-detection
```

## 📄 License

(TBD)

---

**Last Updated:** 2026-03-17
**Status:** Active Development
