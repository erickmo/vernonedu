# Siswa Form Screen — Layout Spec

> Create / edit student form.

---

**Route:** `/students/new` (mode: Baru) or `/students/:studentId/edit` (mode: Edit)
**Title:** Siswa: Baru (or Siswa: Edit)

## Form Fields

Based on StudentDetailEntity specification:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Nama | text input | ✅ | — |
| Email | text input (email) | ✅ | — |
| Telepon | text input (phone) | ❌ | — |
| NIK | text input | ❌ | — |
| Jenis Kelamin | dropdown (Laki-laki / Perempuan) | ❌ | — |
| Alamat | textarea | ❌ | — |
| Tanggal Lahir | date picker | ❌ | — |
| Departemen | dropdown (ajax search) | ❌ | — |
| Status | dropdown (Aktif / Tidak Aktif / Lulus) | ✅ | Default: Aktif |
| Kode Siswa | text input | ❌ | Auto-generated if empty |

## Actions

- **Simpan** button → creates or updates student
- **Batal** button → navigates back to previous screen

## Validation

- Email must be valid format
- Email must be unique (server-side validation)
- Nama is required (min 2 characters)

---

**Last Updated:** Maret 2026
