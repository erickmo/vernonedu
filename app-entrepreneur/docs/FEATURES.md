# Features Documentation

## Business Ideation — Canvas-Based Worksheets

### Overview
Worksheet page menggunakan canvas-based approach dengan sticky notes untuk ideation tools. Setiap worksheet type memiliki layout spesifik yang mencerminkan structure framework-nya.

**Tanggal Implementation:** 2026-03-17
**Status:** ✅ Completed

### Supported Worksheet Types

#### 1. Business Model Canvas (BMC)
**Key:** `business-model-canvas`

9-blok layout untuk merancang model bisnis:

```
┌──────────┬────────────┬─────────────┬──────────────┬────────────┐
│ Key      │ Key        │ Value       │ Customer     │ Customer   │
│ Partners │ Activities │ Propositions│ Relationships│ Segments   │
│          │ Key        │             │ Channels     │            │
│          │ Resources  │             │              │            │
├──────────┴────────────┴─────────────┴──────────────┴────────────┤
│ Cost Structure                         │ Revenue Streams            │
└──────────────────────────────────────┴──────────────────────────┘
```

**Sections:**
- Key Partners
- Key Activities
- Key Resources
- Value Propositions
- Channels
- Customer Relationships
- Customer Segments
- Cost Structure
- Revenue Streams

**Cross-Linking:**
- Channels → Customer Segments, Value Propositions
- Customer Relationships → Customer Segments
- Revenue Streams → Customer Segments, Value Propositions
- Key Activities → Value Propositions, Key Resources
- Key Resources → Key Activities
- Key Partnerships → Key Activities, Key Resources
- Cost Structure → Key Activities, Key Resources
- Customer Segments → Value Propositions
- Value Propositions → Customer Segments

---

#### 2. Value Proposition Canvas (VPC)
**Key:** `value-proposition`

2-sisi layout: Value Map vs Customer Profile

**Left Side — Value Map:**
```
Pain Relievers │ Products & Services │ Gain Creators
```

**Right Side — Customer Profile:**
```
           Customer Jobs
                 │
Pains (left) ─── │ ─── Gains (right)
```

**Sections:**
- Products & Services
- Pain Relievers
- Gain Creators
- Customer Jobs
- Pains
- Gains

---

#### 3. Design Thinking
**Key:** `design-thinking`

5-tahap linear framework:

```
[Empathize] → [Define] → [Ideate] → [Prototype] → [Test]
```

**Sections:**
- Empathize: Pahami user dan masalahnya
- Define: Rumuskan problem statement
- Ideate: Brainstorm ide solusi
- Prototype: Buat prototype/mockup
- Test: Validasi solusi

---

#### 4. PESTEL Analysis
**Key:** `pestel`

6-kategori grid (3x2):

```
┌─────────────┬──────────────┬────────┐
│ Political   │ Economic     │ Social │
├─────────────┼──────────────┼────────┤
│ Technological│Environmental│ Legal  │
└─────────────┴──────────────┴────────┘
```

**Sections:**
- Political: Regulasi, kebijakan pemerintah
- Economic: Kondisi ekonomi, inflasi, daya beli
- Social: Tren sosial, demografi, budaya
- Technological: Teknologi, inovasi
- Environmental: Faktor lingkungan, sustainability
- Legal: Hukum, perizinan, regulasi

---

#### 5. Flywheel Marketing
**Key:** `flywheel-marketing`

3 main + 2 support cards:

```
┌─────────────┬──────────┬──────────┐
│ Attract     │ Engage   │ Delight  │
├─────────────┴──────────┴──────────┤
│ Friction Points  │  Force (Accelerators) │
└──────────────────┴──────────────────────┘
```

**Sections:**
- Attract: Menarik calon customer
- Engage: Membangun hubungan
- Delight: Membuat customer puas & loyal
- Friction Points: Hambatan flywheel
- Force (Accelerators): Akselerator flywheel

---

### Canvas Architecture

#### Data Structure

```dart
// Canvas item model
class CanvasItem {
  final String id;        // Unique identifier (DateTime.now().microsecond)
  String text;            // Main content (editable)
  String note;            // Expandable note section
  bool isExpanded;        // Toggle note visibility
}

// State management (local StatefulWidget)
late final Map<String, List<CanvasItem>> _sectionItems;
late final Map<String, GlobalKey> _sectionKeys;
```

#### Widget Hierarchy

```
WorksheetPage (StatefulWidget)
├─ _buildCanvasContent()
│  ├─ BMCCanvasWidget / VPCCanvasWidget / DTCanvasWidget / etc.
│  └─ CanvasSectionWidget (per section)
│     ├─ Header + color indicator
│     ├─ Linked-section chips (BMC only)
│     ├─ Wrap<CanvasStickyNoteWidget> (items)
│     └─ Add item button (+)
└─ _buildActions()
   ├─ Simpan Draft button
   └─ Submit button
```

---

### Widget Details

#### 1. CanvasStickyNoteWidget
**File:** `canvas_sticky_note_widget.dart`

**Features:**
- ✏️ Inline text editing
- 📝 Expandable note section (toggle show/hide)
- ❌ Delete button (X) di pojok kanan atas
- 💬 Note preview dengan "Lihat" / "Tutup" toggle
- 🎨 Background color sesuai section (semi-transparent)

**Size:** 160px width, min 120px height

**State Management:**
```dart
TextEditingController _textController;
TextEditingController _noteController;
FocusNode _textFocus;
```

#### 2. CanvasSectionWidget
**File:** `canvas_section_widget.dart`

**Features:**
- 🏷️ Section title dengan color indicator
- 🔗 Linked-section chips dengan click-to-scroll
- 📦 Wrap of sticky notes
- ➕ Add item button dengan icon

**Callbacks:**
```dart
OnItemUpdate(CanvasItem updatedItem)  // Update item
OnItemDelete(String itemId)            // Delete item
OnAddItem(String sectionId)            // Add new item
```

#### 3. Canvas Layout Widgets

**BMCCanvasWidget** — 9-blok grid dengan borders
**VPCCanvasWidget** — 2-sisi column layout
**DTCanvasWidget** — 5-tahap linear dengan panah
**PestelCanvasWidget** — 3x2 grid layout
**FlywheelCanvasWidget** — 3+2 card layout

**Common Features:**
- ✅ Desktop layout: complex grid/column arrangements
- ✅ Mobile layout: fallback ke vertical list dengan cards
- ✅ Responsive breakpoint: 1200px (AppDimensions.breakpointDesktop)

---

### User Interactions

#### Adding Item
1. User klik tombol "Tambah Item" (+) di section
2. New `CanvasItem` dibuat dengan `id = DateTime.now().microsecond.toString()`
3. Item ditambah ke `_sectionItems[sectionId]`
4. Widget re-render dengan new sticky note
5. TextEditingController auto-focus di new item

#### Editing Item
1. User klik sticky note → TextEditingController bisa diedit langsung
2. Perubahan text trigger `onTextChanged` callback
3. State update dengan `_updateItem(updatedItem)`
4. Widget re-render dengan perubahan

#### Expanding Note
1. User klik "Catatan" / "Lihat" / "Tutup" link
2. Toggle `item.isExpanded` state
3. Note section muncul/hilang dengan smooth transition
4. TextEditingController untuk note siap diedit

#### Deleting Item
1. User klik ✕ button di pojok kanan atas sticky note
2. Trigger `onDelete` callback
3. Item dihapus dari `_sectionItems[sectionId]`
4. Widget re-render tanpa sticky note

#### Scrolling to Section (BMC only)
1. User klik linked-section chip (e.g., "Value Props ↗")
2. `_scrollToSection()` dipanggil dengan target section ID
3. `Scrollable.ensureVisible()` scroll ke GlobalKey target
4. Smooth animation (500ms, easeInOut curve)

---

### State Management Flow

```
WorksheetPage (_WorksheetPageState)
├─ initState()
│  ├─ Initialize ScrollController
│  ├─ Initialize Map<String, List<CanvasItem>> _sectionItems
│  ├─ Initialize Map<String, GlobalKey> _sectionKeys
│  └─ _initializeCanvasSections() → populate section IDs
│
├─ _addItem(String sectionId)
│  └─ setState() → _sectionItems[sectionId].add(newItem)
│
├─ _updateItem(CanvasItem updatedItem)
│  └─ setState() → find & update item in matching section
│
├─ _deleteItem(String itemId)
│  └─ setState() → find & remove item from all sections
│
└─ dispose()
   └─ Dispose ScrollController & TextEditingControllers
```

---

### Responsive Behavior

| Breakpoint | Behavior |
|-----------|----------|
| ≥1200px | Desktop layout (complex grids/columns) |
| <1200px | Mobile layout (vertical list with cards) |

**Desktop Examples:**
- BMC: 5-column top row + 2-column bottom row
- VPC: Side-by-side Value Map & Customer Profile
- DT: Horizontal 5-stage dengan panah kanan
- PESTEL: 3x2 grid dengan borders
- Flywheel: 3+2 grid layout

**Mobile Examples:**
- Semua: Single column vertical list
- Cards: Padding 16px, border radius 8px, divider
- Panah: Vertikal dengan panah bawah (untuk DT)

---

### Colors & Styling

**Section Colors:**

| Section | Color | Hex |
|---------|-------|-----|
| Customer Segments | Green | #10B759 |
| Value Propositions | Orange | #FF6F00 |
| Channels | Blue | #0168FA |
| Customer Relationships | Purple | #9C27B0 |
| Revenue Streams | Cyan | #00BCD4 |
| Key Resources | Deep Orange | #FF5722 |
| Key Activities | Deep Purple | #673AB7 |
| Key Partnerships | Amber | #FFC107 |
| Cost Structure | Pink | #E91E63 |

**Sticky Note Styling:**
- Background: `sectionColor.withValues(alpha: 0.08)` (semi-transparent)
- Border: `sectionColor.withValues(alpha: 0.3)` (1px)
- Border Radius: 4px
- Shadow: 0.08 opacity, 4px blur, 0 offset

---

### Testing Checklist

#### Functionality
- [ ] Add item → sticky note muncul dengan auto-focus
- [ ] Edit text → perubahan terupdate di state
- [ ] Expand note → note section toggle show/hide
- [ ] Edit note → perubahan terupdate di state
- [ ] Delete item (X button) → item hilang dari section
- [ ] BMC: Click linked-section chip → scroll ke target section

#### Responsive
- [ ] Desktop (≥1200px): Layout sesuai framework
- [ ] Tablet: Layout sesuai framework
- [ ] Mobile (<1200px): Fallback ke vertical list
- [ ] Mobile: Cards dengan proper padding & border radius

#### State Management
- [ ] Add multiple items → semua terupdate di section
- [ ] Edit item → state sync dengan UI
- [ ] Delete item → section list terupdate
- [ ] Switch worksheet type → section items reset

#### UX
- [ ] Text auto-focus saat item baru dibuat
- [ ] Note section smooth expand/collapse
- [ ] Color coding jelas per section
- [ ] Linked chips jelas & clickable
- [ ] Add button jelas & prominent

---

### Known Limitations

1. **Local State Only**: Perubahan tidak disimpan ke backend (TODO: integrate with BLoC)
2. **No Persistence**: Reload page → data hilang (TODO: local storage atau backend API)
3. **No Collaboration**: Single-user only (TODO: real-time sync)
4. **No Undo**: Tidak bisa undo/redo perubahan (TODO: history stack)
5. **No Validation**: Tidak ada validasi content saat submit (TODO: add validators)

---

### Future Enhancements

- [ ] Auto-save ke local storage (shared_preferences)
- [ ] Backend integration untuk persist data
- [ ] Undo/redo functionality
- [ ] Content validation & error messages
- [ ] Export to PDF/image
- [ ] Share/collaborate dengan mentor
- [ ] Template suggestions
- [ ] AI-powered content recommendations
- [ ] Analytics & progress tracking

---

**Last Updated:** 2026-03-17
**Maintainer:** AI-Generated
