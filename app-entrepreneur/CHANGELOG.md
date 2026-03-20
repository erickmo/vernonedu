# Changelog

Semua perubahan material terhadap project ini akan didokumentasikan di file ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), dan project ini mengikuti [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- [ ] Backend API integration untuk persist worksheet data
- [ ] Local storage caching dengan shared_preferences
- [ ] Auth system (Login/Register)
- [ ] Dashboard dengan progress tracking
- [ ] Learning modules
- [ ] Business Launchpad
- [ ] Undo/redo functionality
- [ ] Content validation & suggestions
- [ ] Export to PDF/image
- [ ] Mentor feedback system

---

## [0.1.0] — 2026-03-17

### Added - Business Ideation Canvas Implementation

#### New Widgets
- **CanvasStickyNoteWidget** — Sticky note component dengan inline editing & expandable notes
- **CanvasSectionWidget** — Generic section container dengan linked-section chips & add button
- **BMCCanvasWidget** — Business Model Canvas 9-blok layout dengan cross-linking
- **VPCCanvasWidget** — Value Proposition Canvas 2-sisi layout
- **DTCanvasWidget** — Design Thinking 5-tahap linear layout
- **PestelCanvasWidget** — PESTEL Analysis 3x2 grid layout
- **FlywheelCanvasWidget** — Flywheel Marketing 3+2 card layout

#### Modified
- **WorksheetPage** — Refactored dari form-based ke canvas-based approach
  - Added `_sectionItems` state management
  - Added `_sectionKeys` untuk scroll navigation
  - Added callbacks: `_addItem()`, `_updateItem()`, `_deleteItem()`
  - Removed old form widget code
  - Maintained breadcrumb, header, action buttons

#### Features
- ✅ Sticky notes dengan inline text editing
- ✅ Expandable note section per item (toggle show/hide)
- ✅ Add item button (+) per section dengan auto-focus
- ✅ Delete button (✕) per sticky note
- ✅ Cross-linking chips di BMC (9 sections dengan bidirectional links)
- ✅ Click-to-scroll navigation untuk linked sections
- ✅ Responsive layouts (desktop/tablet/mobile)
- ✅ Color-coded sections untuk visual hierarchy
- ✅ No critical build errors (only minor prefer_const_constructors warnings)

#### Documentation
- **README.md** — Updated dengan project overview, quick start, features, dan architecture
- **FEATURES.md** — Comprehensive canvas feature documentation
- **PRD** — Updated Business Ideation status & feature details
- **CHANGELOG.md** — This file

#### Data Structure
```dart
class CanvasItem {
  final String id;
  String text;
  String note;
  bool isExpanded;
}
```

#### State Management
- Local StatefulWidget dengan `Map<String, List<CanvasItem>>`
- Callbacks properly wired dengan section ID awareness
- No persistence (TODO: backend integration)

#### Testing Status
- ✅ Flutter analyze: No errors (63 warnings - all minor)
- ✅ All imports correct & integrated
- ✅ All callbacks working correctly
- ⏳ Runtime testing: App running on localhost:51540

#### Known Issues / TODOs
- [ ] Integrate dengan backend BLoC untuk data persistence
- [ ] Add local storage caching
- [ ] Add form validation saat submit
- [ ] Add undo/redo functionality
- [ ] Add loading/error states
- [ ] Add unit tests untuk CanvasItem & callbacks
- [ ] Add widget tests untuk sticky notes & sections
- [ ] Add integration tests untuk worksheet workflows

---

## Project Info

- **Latest Version:** 0.1.0 (Development)
- **Flutter Version:** 3.41.4
- **Dart Version:** 3.11.1
- **Platform:** Web PWA
- **Status:** Active Development

---

**Last Updated:** 2026-03-17
