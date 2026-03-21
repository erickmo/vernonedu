# Student List Screen — Layout Spec

> Student list and management screen.

---

**Route:** `/students`
**Title:** Siswa
**Subtitle:** Manajemen Siswa

## Action

`+ Tambah Siswa` button → navigates to Siswa Form Screen (mode: Baru)

## Filters Row

- Nama (text input)
- Telp (text input)
- Email (text input)
- Status Siswa (dropdown: Aktif / Tidak Aktif / Lulus)

## Content: Table

| Nama | Email - Telp | Course Batch Aktif | Course Batch Selesai | Tanggal Bergabung | Status |
|------|-------------|-------------------|---------------------|------------------|--------|
| [name] | [email] - [phone] | [count] | [count] | [date] | [status pill] |

**On row click:** Navigate to → Siswa Detail Screen (`/students/:studentId`)

---

**Last Updated:** Maret 2026
