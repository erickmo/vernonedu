# Spec: Halaman Struktur Pendidikan

**Date:** 2026-05-06  
**Status:** Approved

---

## Overview

Halaman baru `Struktur` di bawah seksi **Pendidikan** di sidebar. Menampilkan hirarki visual:

```
Departemen → Course (MasterCourse) → Batch Summary (aktif/selesai + progress)
```

Tujuan: semua user yang dapat akses Pendidikan bisa memahami struktur organisasi pendidikan secara visual. Role yang sesuai bisa langsung create dari halaman ini.

---

## Route & Nav

- **Route:** `pendidikan/struktur`
- **Nav item:** tambah ke seksi `pendidikan` di `navItems.ts`, setelah `Kurikulum` (index 1)
- **Access:** `canManageCourse(ctx) || hasRole(ctx, 'facilitator')`
- **Label:** `Struktur`
- **Icon:** `Network` (dari Lucide)

---

## Tampilan

### Default View: Card Tree

```
[Header: "Struktur Pendidikan"]   [toggle: ⊞ Card | ≡ Tree]

[Dept Card — bg #4D2975]
  label: nama dept, badge: N course, CTA: "+ Course" (role-gated), "+ Departemen" (role-gated)

  [Course Row — bg #F0E8FA]
    label: nama course, link "Lihat detail →"
    [Batch Chips — horizontal scroll]
      [Chip aktif]  status dot hijau, nama batch, N siswa, progress bar
      [Chip selesai]  status dot abu, nama batch, opacity 0.7
      [+ Batch]  dashed border (role-gated)

  [Course Row collapsed]
    label + badge aktif count + selesai count + "+ Batch" (role-gated)

[+ Tambah Departemen]  dashed border (role-gated: director, education_leader)
```

### Toggle View: Tree/Accordion

Nested list. Dept → expand → Course list → expand → Batch list (status + siswa + progress).

### View persistence

Simpan pilihan view ke `localStorage` key `struktur_view` (`card` | `tree`). Default: `card`.

---

## Data Strategy

1. **Departments:** `departmentService.list()` — load semua on mount
2. **Courses per dept:** `departmentService.getCourses(deptId)` — parallel per dept on mount
3. **Batches per course:** `courseBatchService.list({ course_id: id, limit: 10 })` — load on mount parallel per course

Data di-compose di page-level. Tidak ada dedicated struktur endpoint.

Response shape batch: ambil via `res.data.data` (double-nested paginated) atau `res.data` (array langsung) — gunakan extraction helper dari CLAUDE.md.

---

## Role-Based CTAs

| CTA | Roles yang bisa lihat |
|-----|----------------------|
| `+ Tambah Departemen` | `director`, `education_leader` |
| `+ Course` (per dept) | `director`, `education_leader`, `dept_leader` |
| `+ Batch` (per course) | `director`, `education_leader`, `dept_leader`, `course_owner`, `operation_admin` |

Navigasi CTA:
- `+ Tambah Departemen` → `/pengembangan/departments/new`
- `+ Course` → `/course/new` (dengan `dept_id` query param jika API mendukung pre-fill)
- `+ Batch` → `/course-batches/new` (dengan `course_id` query param jika API mendukung pre-fill)

Facilitator: lihat struktur saja, tidak ada CTA create.

---

## Components

```
src/pages/Course/
  StrukturPage.tsx          ← halaman utama, fetch + compose data, toggle state
  components/
    DeptCard.tsx            ← card dept + daftar course rows
    CourseRow.tsx           ← satu baris course + batch chips
    BatchChip.tsx           ← satu chip batch (status, siswa, progress bar)
    StrukturTreeView.tsx    ← tree/accordion view alternatif
```

---

## Warna Brand

- Dept header: `--color-primary` (`#4D2975`)
- Dept header collapsed: `--color-primary-hover` (`#3D1F5E`)
- Course row bg: `--color-surface-alt` (`#F0E8FA`)
- Course border: `rgba(77,41,117,0.15)`
- Batch chip bg: `--color-surface-elevated` (white)
- Batch chip border: `--color-border`
- Active dot: `--color-success` (`#16A34A`)
- Done dot: `--color-text-tertiary` (`#9E96AE`)
- CTA "+ Batch": dashed `--color-primary`
- CTA "+ Dept": dashed `--color-primary`, bg `--color-primary-subtle`
- CTA badge "+ Course": `--color-secondary` (`#E9A800`)

---

## Testing

- Unit test: `StrukturPage.test.tsx` — mock department + course + batch data, assert card render
- Test cases: empty state (no dept), no courses in dept, no batches in course, role-gated CTAs hidden/visible

---

## Out of Scope

- Inline edit nama dept/course dari halaman ini
- Drag & drop reorder
- Mindmap/graph view (ditambah nanti jika diperlukan)
- Filter/search di halaman ini
