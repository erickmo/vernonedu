# Course Form Grouping — UI/UX Redesign

**Date:** 2026-05-06
**Scope:** `web-dashboard/src/pages/Course/CourseFormPage.tsx`
**Goal:** Reorganize flat field list into logical sections for better usability.

---

## Problem

All 8 fields in a single flat column with no visual grouping. User cannot distinguish required vs optional fields, or understand field relationships at a glance.

---

## Solution: FieldSection Cards (3 sections)

Use existing `FieldSection` widget to wrap related fields into titled cards. Use `FieldRow` for short side-by-side fields to reduce vertical scroll.

---

## Layout Design

### Section 1 — Identitas Kursus (required)

| Mode | Fields |
|------|--------|
| Create | `FieldRow`: Kode Kursus (flex: 0 0 160px) + Nama Kursus (flex: 1) |
| Edit | Nama Kursus — full width |
| Both | Bidang Studi — full width SearchableSelect |

All fields in this section are `required`. User fills these first.

### Section 2 — Organisasi & Konfigurasi (optional)

```
FieldRow: [Departemen]  [Course Owner]
[URL Supporting App]   ← full width, optional hint
```

Administrative fields. Optional — lower visual weight by position.

### Section 3 — Konten Kurikulum (optional)

```
[Kompetensi Inti]   ← TagInput, multiple values via Enter key
[Deskripsi]         ← textarea, rows=4, resize: vertical
```

Content fields placed last — lower priority for initial creation.

### Sidebar (edit mode only)

```
[Informasi card]
  - Dibuat: timestamp
  - Diperbarui: timestamp
```

---

## Component Usage

| Widget | Usage |
|--------|-------|
| `FieldSection` | Wraps each section with titled card |
| `FieldRow` | Kode+Nama (create), Departemen+Owner |
| `Field` | Individual field wrapper (unchanged) |
| `FormGrid` / `FormColumn` | Outer layout (unchanged) |

---

## Scope Boundaries

- **No logic changes** — state, validation, submit handler unchanged
- **No new fields** — same 8 fields, reorganized only
- **CourseType not included** — managed in CourseDetail/Dashboard page (child entity, needs parent ID)
- **Curriculum/CourseFormPage.tsx not in scope** — separate simpler form

---

## Files Changed

| File | Change |
|------|--------|
| `web-dashboard/src/pages/Course/CourseFormPage.tsx` | JSX reorganization only |

---

## Non-Goals

- CourseType management in this form
- New fields or API changes
- Curriculum/CourseFormPage changes
