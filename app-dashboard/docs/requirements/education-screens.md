# Education Screens — Layout Spec

> All screens under the Education domain in app-dashboard.

---

## 1. Education Main Screen

**Route:** `/curriculum`
**Title:** Manajemen Edukasi
**Subtitle:** Kelola Course, Course Batch, Module dan Enrollment

### Statistics Section

3 number cards in a row:

| Card | Value | Extra Info |
|------|-------|-----------|
| Total Course | count | — |
| Course Batch Berjalan | count | + number of enrolled students |
| Course Batch Mendatang | count | + enrollment count / max students |

### Tabs

#### Tab 1: Course

**Filters row:**
- Search by name (text input)
- Status: Aktif / Tidak Aktif (dropdown/pills)
- Department (dropdown)

**Action:** If user has permission → `+ Tambah Course` button

**Content:** Card grid with pagination (24 per page)

**Course Card contents:**
```
┌─────────────────────────────────────┐
│ [Title]                    [Status] │
│ Code: [course_code]                 │
│ Course Owner: [name]                │
│ [description — max 2 lines, ...     │
│  truncate with ellipsis]            │
│─────────────────────────────────────│
│ Course Batch:                       │
│   Berjalan: X  Akan Datang: X      │
│   Selesai: X                        │
│─────────────────────────────────────│
│ Program Owner: [name]               │
│ Price: [min_price] - [max_price]    │
│ Types: ☑ Reguler ☑ Karir ☑ Privat  │
└─────────────────────────────────────┘
```

**On click:** Navigate to → Course Detail Screen (`/curriculum/:courseId`)

---

#### Tab 2: Course Batch

**Filters row:**
- Course name (text input)
- Status: Berjalan / Akan Datang / Selesai (dropdown/pills)
- Course (select dropdown)

**Action:** If user has permission → `+ Tambah Course Batch` button

**Content:** Card grid with pagination (24 per page)

**Course Batch Card contents:**
```
┌─────────────────────────────────────┐
│ [Course name]                       │
│ Branch: [branch_name]               │
│ Students: [enrolled] / [min-max]    │
│ Price: [batch_price]                │
└─────────────────────────────────────┘
```

**On click:** Navigate to → Course Batch Detail Screen (`/course-batches/:batchId`)

---

## 2. Course Detail Screen

**Route:** `/curriculum/:courseId`

### Header

- **Breadcrumb:** Manajemen Edukasi → Course → [Course Name]
- **Title:** [Course Name] + [Course Code] + [Status pill badge]
- **Actions (if permitted):**
  - `+ Buat Course Batch` button
  - `Edit Course` button

### Statistics Section

4 number cards in a row:

| Card | Value |
|------|-------|
| Batch Berjalan | count |
| Course Batch Selesai | count |
| Course Batch Akan Datang | count |
| Total Siswa | count |

### Main Card with Tabs (padded interior)

#### Tab 1: Overview

Two-column layout:

| Column 1 | Column 2 |
|-----------|----------|
| **Deskripsi** — full course description | **Syarat Peserta** — participant requirements |
| **Course Owner** — owner name + info | **Rekomendasi Lanjutan** — recommended follow-up courses |

---

#### Tab 2: Tipe Kelas

Sub-tabs for each course type: **Program Karir | Reguler | Privat | Kolaborasi Sekolah | Kolaborasi Universitas | Inhouse Training**

Per sub-tab content:
```
Status: [Aktif / Tidak Aktif]
Harga: [min_price] - [max_price]
Siswa: [min_student] - [max_student]
Versi saat ini: [version_number] (update [date])

[If permitted: "Propose New Version" button → navigates to Propose New Version Screen]

Modul Table:
┌────┬──────────────────────┬───────────┬───────┐
│ No │ Judul                │ Jumlah Sesi│ Files │
├────┼──────────────────────┼───────────┼───────┤
│ 1  │ Pengenalan HTML      │ 3         │ 📎 2  │
│ 2  │ CSS Dasar            │ 2         │ 📎 1  │
│ ...│ ...                  │ ...       │ ...   │
└────┴──────────────────────┴───────────┴───────┘
```

---

#### Tab 3: Jadwal

Two-column layout (2:1 ratio):

| Column 1 (2/3) | Column 2 (1/3) |
|-----------------|-----------------|
| Calendar view with dots on dates that have schedules | List of events/schedules for this course (scrollable) |

---

#### Tab 4: Fasilitator

**Action (if permitted):** `Propose Perubahan Fasilitator` button

**Facilitator Table:**

| Nama | Jadi Fasilitator Sejak | Level Fasilitator | Kelas Dihandle |
|------|----------------------|-------------------|----------------|
| [name] | [date] | Level [n] | [batch count / list] |

---

#### Tab 5: Siswa

**Filters row:**
- Nama (text input)
- No Telp (text input)
- Status (dropdown)
- Certificate Status: Certificate of Competence / Certificate of Participant (dropdown/pills)

**Content:** Card grid of students

**Student Card contents:**
```
┌─────────────────────────────────────┐
│ [Student Name]                      │
│ Phone: [phone_number]               │
│ Batch: [course_batch_code]          │
│ Status: [batch_status]              │
└─────────────────────────────────────┘
```

---

#### Tab 6: Talent Pool

**Statistics Cards:**
- Total Siswa di Talent Pool
- Total Aktif di Pool

**Section: Goal Profession**
- List of professions with title + level
- (API: add profession data with `title`, `level` fields)

**Section: Pool List**

**Filters:**
- Name (text input)
- Batch (dropdown)
- Status (dropdown/pills)

**Content:** List of students in the talent pool

---

## 3. Course Batch Detail Screen

**Route:** `/course-batches/:batchId`

### Header

- **Breadcrumb:** Manajemen Edukasi → [Previous Screen] → Course Batch: [Batch Name]
- **Title:** [Batch Name] + [Status pill badge]

### Metadata Card

Card displaying course batch metadata: course name, branch, facilitator, dates, pricing, payment method, enrollment count, min/max students, website visibility, etc.

### Main Card with Tabs

#### Tab 1: Jadwal + Calendar

Class schedule view with calendar integration:
- Calendar showing session dates
- List/table of scheduled sessions with: date, time, module, room, facilitator

#### Tab 2: Module

Module list for this batch's course version:
- Table: No, Judul, Jumlah Sesi, Tools/Requirements, Status (completed/upcoming)

#### Tab 3: Students

**Filters:** Name, Status, Payment Status

**Content:** List of enrolled students with: name, enrollment date, attendance rate, payment status, certificate status

---

## 4. Propose New Version Screen

**Route:** `/curriculum/propose-version` (or modal/dialog)

### Form

1. **Select Course** — ajax/async search dropdown (type to search courses)
2. **Select Type** — dropdown of course types for the selected course (Program Karir, Reguler, etc.)
3. **Editable Module Table:**

| No | Judul | Jumlah Sesi | Files | Actions |
|----|-------|-------------|-------|---------|
| 1  | [editable] | [editable] | [upload] | ↑ ↓ 🗑 |
| 2  | [editable] | [editable] | [upload] | ↑ ↓ 🗑 |
| +  | Add Module | | | |

- Rows are draggable or have up/down arrows for reordering
- Each row can be deleted
- "Add Module" row at bottom to append new modules
- **Submit** button → creates approval request (Course Version Change → approved by Dept Leader)

---

## API Requirements (from screen specs)

### New/Updated endpoints needed:

```
# Talent Pool — Profession Goals
GET    /talent-pool/professions          → list of profession goals
POST   /talent-pool/professions          body: {title, level}
PUT    /talent-pool/professions/:id
DELETE /talent-pool/professions/:id

# Course Version Proposal
POST   /course-versions/propose          body: {courseTypeId, modules[{title, sessionCount, files?}]}
```

---

**Last Updated:** Maret 2026
