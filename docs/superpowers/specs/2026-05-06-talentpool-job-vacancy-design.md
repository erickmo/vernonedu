# TalentPool — Job Vacancy Feature Design Spec

**Date:** 2026-05-06  
**Author:** Brainstorming session  
**Status:** Approved

---

## Overview

Tambah fitur **Lowongan Kerja (Job Vacancy)** ke TalentPool domain. Partner resmi VernonEdu atau Staff dapat memposting lowongan. Staff dapat merekomendasikan talent dari TalentPool, atau talent dapat apply mandiri. Pipeline aplikasi dilacak hingga status hired, yang otomatis men-trigger `MarkPlaced` di TalentPool entry.

---

## Domain Model

### Entitas: `Vacancy`

| Field | Type | Keterangan |
|-------|------|------------|
| ID | uuid | Primary key |
| PartnerID | uuid | FK ke Partner — wajib, partner tidak harus punya MOU aktif |
| Title | string | Nama posisi |
| Description | string | Deskripsi pekerjaan |
| Requirements | string | Teks bebas syarat kandidat |
| Salary | *SalaryRange | `{min, max, currency}` — nullable |
| Status | string | `draft \| open \| closed \| filled` |
| Quota | int | Jumlah posisi terbuka |
| PostedBy | uuid | User ID yang membuat vacancy |
| PostedByRole | string | `"partner" \| "staff"` |
| OpenedAt | *time.Time | Set saat status → open |
| ClosedAt | *time.Time | Set saat status → closed/filled |
| CreatedAt | time.Time | |
| UpdatedAt | time.Time | |

### Entitas: `VacancyApplication`

| Field | Type | Keterangan |
|-------|------|------------|
| ID | uuid | Primary key |
| VacancyID | uuid | FK ke Vacancy |
| TalentPoolID | uuid | FK ke TalentPool entry |
| ApplicantType | string | `"self"` (talent apply) \| `"recommended"` (staff recommend) |
| RecommendedBy | *uuid | User ID staff — null jika self-apply |
| Status | string | `applied \| reviewed \| interview \| hired \| rejected` |
| Notes | string | Catatan staff per tahap |
| AppliedAt | time.Time | |
| UpdatedAt | time.Time | |

### Business Rules

1. Vacancy dapat dibuat selama Partner terdaftar di sistem (MOU tidak wajib aktif)
2. TalentPool entry harus berstatus `active` untuk bisa apply atau direkomendasikan
3. Satu talent tidak bisa apply ke vacancy yang sama dua kali → 409
4. Saat aplikasi di-`hired`: otomatis panggil `TalentPool.MarkPlaced(PlacementRecord{CompanyName, Position, PlacedAt})`
5. Jika hired count ≥ quota → vacancy otomatis berubah ke `filled`
6. Semua side-effect (placed + filled) dieksekusi dalam satu DB transaction

### Status Transitions

```
Vacancy:          draft → open → closed
                              ↘ filled (auto)

VacancyApplication: applied → reviewed → interview → hired
                                                   ↘ rejected
                              ↘ rejected
```

---

## API Endpoints

### Vacancy

```
POST   /talent-pool/vacancies                  Create vacancy
GET    /talent-pool/vacancies                  List (filter: status, partner_id)
GET    /talent-pool/vacancies/:id              Detail
PUT    /talent-pool/vacancies/:id              Update (title, desc, req, salary, quota)
PATCH  /talent-pool/vacancies/:id/status       Ubah status
DELETE /talent-pool/vacancies/:id              Soft delete
```

### Applications

```
POST   /talent-pool/vacancies/:id/applications   Self-apply atau staff recommend
GET    /talent-pool/vacancies/:id/applications   List aplikasi per vacancy
GET    /talent-pool/applications                 List semua aplikasi (filter: status, talent_pool_id)
PATCH  /talent-pool/applications/:id/status      Update status pipeline
```

**`POST /applications` body:**
```json
{
  "talent_pool_id": "uuid",
  "applicant_type": "self | recommended",
  "recommended_by": "uuid | null"
}
```

---

## Error Handling

| Kondisi | HTTP | Error Key |
|---------|------|-----------|
| Partner tidak ditemukan | 404 | `partner_not_found` |
| Vacancy tidak ditemukan | 404 | `vacancy_not_found` |
| TalentPool entry tidak `active` | 422 | `talent_not_active` |
| Talent sudah apply ke vacancy yang sama | 409 | `duplicate_application` |
| Status transition tidak valid | 422 | `invalid_status_transition` |
| Hired saat quota penuh | 422 | `quota_exceeded` |
| Application tidak ditemukan | 404 | `application_not_found` |

---

## Frontend

### Routes

```
/admin/talent-pool/vacancies                  VacancyListPage
/admin/talent-pool/vacancies/new              VacancyFormPage (create)
/admin/talent-pool/vacancies/:id              VacancyDetailPage
/admin/talent-pool/vacancies/:id/edit         VacancyFormPage (edit)
```

### Pages

**VacancyListPage**
- Table: title, partner name, status badge, quota, hired count, created date
- Filter: status, partner
- CTA: Buat Lowongan

**VacancyFormPage** (create + edit)
- Fields: partner (dropdown), title, description, requirements, salary range (optional), quota, status (draft/open)
- After save → VacancyDetailPage

**VacancyDetailPage**
- Header: info vacancy + status badge + quick-action (open/close)
- Tab **Informasi**: semua field vacancy
- Tab **Aplikasi**: list VacancyApplication (nama talent, tipe, status pipeline, notes) + action update status
- Button: **Rekomendasikan Talent** → RecommendTalentModal

### Shared Components

- `VacancyStatusBadge` — draft(gray), open(green), closed(red), filled(blue)
- `ApplicationStatusBadge` — applied(gray), reviewed(yellow), interview(blue), hired(green), rejected(red)
- `RecommendTalentModal` — staff pilih dari TalentPool list aktif → submit rekomendasi

### Nav

Tambah sub-item **Lowongan** di TalentPool NavSection yang sudah ada.

---

## Testing Strategy

### Go Unit Tests
- Vacancy domain: status transitions, quota logic, duplicate application guard
- TalentPool domain: MarkPlaced dipanggil saat hired

### Go Integration Tests
- Full CRUD vacancy via HTTP handler
- Pipeline: apply → reviewed → interview → hired → assert TalentPool.status = placed
- Duplicate application → 409
- Hired count ≥ quota → vacancy.status = filled

### Frontend Tests
- VacancyListPage: render, filter, navigate to detail
- VacancyFormPage: validation, submit success/error
- RecommendTalentModal: pilih talent, submit → muncul di aplikasi list
