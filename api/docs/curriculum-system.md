# Sistem Kurikulum VernonEdu

Dokumentasi sistem manajemen kurikulum multi-bidang untuk lembaga kursus VernonEdu.

---

## Hierarki Data

```
MasterCourse (L1)
└── CourseType (L2) — 1 sampai 6 tipe per course
    └── CourseVersion (L3) — semantic versioning, independent per tipe
        └── CourseModule (L4) — modul per versi
        └── InternshipConfig  — khusus program_karir
        └── CharacterTestConfig — khusus program_karir

TalentPool — entitas mandiri, diisi otomatis saat peserta lulus character test
```

---

## Tipe Kursus yang Tersedia

| Tipe | Deskripsi | Sertifikasi |
|------|-----------|-------------|
| `regular` | Kursus reguler umum | internal |
| `private` | Kursus privat/one-on-one | internal |
| `company_training` | Pelatihan karyawan perusahaan | corporate |
| `collab_university` | Kolaborasi dengan universitas | SKS |
| `collab_school` | Kolaborasi dengan sekolah | nilai_rapor |
| `program_karir` | Program karir 3 tahap: Pembelajaran → Internship → Character Test | career_certificate |

---

## Program Karir — Alur Khusus

```
Peserta mendaftar program_karir
        ↓
[1] Pembelajaran (modul + tes)
        ↓ (jika gagal → retry / continue_no_cert / disqualified)
[2] Internship (magang di partner company)
        ↓ (jika gagal → retry / continue_no_cert / disqualified)
[3] Character Test (MBTI / DISC / custom)
        ↓
    score >= passing_threshold
    AND talentpool_eligible = true?
        ↓ Ya
    → Auto-insert ke TalentPool VernonEdu
        ↓
    TalentPool dapat referral kerja (placement_history)
```

---

## Versioning Kurikulum

Menggunakan **Semantic Versioning**: `vMAJOR.MINOR.PATCH`

| Change Type | Kapan | Contoh |
|-------------|-------|--------|
| `major` | Restrukturisasi modul, perubahan tujuan kursus | v1.x.x → v2.0.0 |
| `minor` | Penambahan/penghapusan modul | v2.0.x → v2.1.0 |
| `patch` | Koreksi kecil, update materi, perbaikan typo | v2.1.0 → v2.1.1 |

**Status flow:** `draft` → `review` → `approved` → `archived`

Aturan: **Hanya 1 versi yang boleh berstatus `approved` per tipe pada satu waktu.**
Saat versi baru di-approve → versi lama otomatis di-archive.

---

## Database Tables

| Table | Keterangan |
|-------|------------|
| `master_courses` | Entitas utama kursus |
| `course_types` | Tipe pembelajaran per course |
| `course_versions` | Versi kurikulum (semantic versioning) |
| `course_modules` | Modul per versi |
| `internship_configs` | Konfigurasi magang (program_karir) |
| `character_test_configs` | Konfigurasi tes karakter (program_karir) |
| `talentpool` | Pool kandidat kerja dari alumni program_karir |

---

## API Endpoints

### Master Course
```
POST   /api/v1/curriculum/courses                  → Buat course baru
GET    /api/v1/curriculum/courses                  → List courses (filter: status, field)
GET    /api/v1/curriculum/courses/{id}             → Detail course
PUT    /api/v1/curriculum/courses/{id}             → Update course
POST   /api/v1/curriculum/courses/{id}/archive     → Arsipkan course
DELETE /api/v1/curriculum/courses/{id}             → Hapus course
```

### Course Type
```
POST   /api/v1/curriculum/courses/{courseID}/types → Tambah tipe ke course
GET    /api/v1/curriculum/courses/{courseID}/types → List tipe course
GET    /api/v1/curriculum/types/{typeID}           → Detail tipe
PUT    /api/v1/curriculum/types/{typeID}           → Update tipe
POST   /api/v1/curriculum/types/{typeID}/toggle    → Aktifkan / Nonaktifkan tipe
```

### Course Version
```
POST   /api/v1/curriculum/types/{typeID}/versions         → Buat versi baru
GET    /api/v1/curriculum/types/{typeID}/versions         → List versi
GET    /api/v1/curriculum/versions/{versionID}            → Detail versi
POST   /api/v1/curriculum/versions/{versionID}/promote    → Promosikan status
                                                            body: {"target_status": "review"|"approved"}
```

### Course Module
```
POST   /api/v1/curriculum/versions/{versionID}/modules   → Tambah modul
GET    /api/v1/curriculum/versions/{versionID}/modules   → List modul (sorted by sequence)
GET    /api/v1/curriculum/modules/{moduleID}             → Detail modul
PUT    /api/v1/curriculum/modules/{moduleID}             → Update modul
DELETE /api/v1/curriculum/modules/{moduleID}             → Hapus modul
```

### Program Karir (khusus)
```
PUT    /api/v1/curriculum/versions/{versionID}/internship         → Upsert konfigurasi magang
GET    /api/v1/curriculum/versions/{versionID}/internship         → Get konfigurasi magang
PUT    /api/v1/curriculum/versions/{versionID}/character-test     → Upsert konfigurasi character test
GET    /api/v1/curriculum/versions/{versionID}/character-test     → Get konfigurasi character test
PUT    /api/v1/curriculum/types/{typeID}/failure-config           → Update konfigurasi kegagalan komponen
POST   /api/v1/curriculum/versions/{versionID}/submit-test-result → Submit hasil character test
```

### TalentPool
```
GET    /api/v1/talentpool                          → List TalentPool (filter: status, master_course_id)
GET    /api/v1/talentpool/{id}                     → Detail entry TalentPool
PUT    /api/v1/talentpool/{id}/status              → Update status (placed / inactive)
```

---

## Cara Menjalankan Migrations

```bash
cd api

# Jalankan semua migration baru (014-021)
psql $DATABASE_URL -f migrations/014_create_master_courses.sql
psql $DATABASE_URL -f migrations/015_create_course_types.sql
psql $DATABASE_URL -f migrations/016_create_course_versions.sql
psql $DATABASE_URL -f migrations/017_create_course_modules.sql
psql $DATABASE_URL -f migrations/018_create_internship_configs.sql
psql $DATABASE_URL -f migrations/019_create_character_test_configs.sql
psql $DATABASE_URL -f migrations/020_create_talentpool.sql
psql $DATABASE_URL -f migrations/021_seed_curriculum.sql   # seed data contoh
```

Atau via Makefile (jika sudah dikonfigurasi):
```bash
make migrate-up
```

---

## Seed Data yang Tersedia

Setelah menjalankan `021_seed_curriculum.sql`:

1. **Web Development Fullstack** (WDF-001) — field: coding
   - Tipe: `regular` (Rp 5.000.000) + `private` (Rp 8.000.000 – Rp 15.000.000)
   - Regular: v1.0.0 (approved) + v2.0.0 (draft)
   - Private: v1.0.0 (approved)
   - Modul: HTML/CSS, JavaScript, React.js

2. **Program Karir Digital** (PKD-001) — field: coding
   - Tipe: `program_karir` (Rp 7.500.000)
   - v1.0.0 (approved) dengan internship config + character test config (DISC, threshold 70%)
   - `component_failure_config`: pembelajaran → retry, internship → continue_no_cert, character_test → retry

3. **TalentPool** — 2 entry:
   - Andi Pratama (skor 82.5, status: active)
   - Sari Wulandari (skor 91.0, status: placed — sudah ditempatkan di PT Nusantara Digital)

---

## Aturan Bisnis Utama

1. Setiap course wajib punya minimal 1 tipe aktif
2. Setiap tipe aktif wajib punya minimal 1 version dengan status `approved`
3. Hanya 1 version `approved` per tipe pada satu waktu
4. Update version tidak mempengaruhi tipe lain dalam course yang sama
5. Harga wajib diisi jika tipe = `regular` atau `private`
6. Dokumen MOU wajib ada jika tipe = `company_training`, `collab_university`, `collab_school`, atau `program_karir`
7. `program_karir` wajib punya ketiga komponen (internship + character test config) sebelum bisa `approved`
8. Peserta program_karir yang lulus character_test di atas threshold → auto-insert ke TalentPool
9. TalentPool adalah entitas tersendiri, bukan bagian dari course
