# Student Form Card Layout — Design Spec

**Status:** Approved  
**Date:** 2026-05-06

---

## Problem

`StudentFormPage` uses a 4-tab layout. Tabs hide fields from secondary tabs (Alamat, Pendidikan, Kontak Darurat), making it easy to submit incomplete data without noticing. Pendidikan and Kontak Darurat tabs each hold only 2 fields — far too few to justify a tab.

---

## Solution

Convert to single-scroll page with 4 `FieldSection` cards (widget already exists at `web-dashboard/src/widgets/FormPageTemplate/FieldSection.tsx`).

---

## Card Structure

### Card 1 — Identitas Siswa
Fields: Nama* , Email*, Telepon, Jenis Kelamin, Tanggal Lahir, NIK, URL Foto

### Card 2 — Alamat
Fields: Alamat Lengkap, Kota, Provinsi, Kode Pos

### Card 3 — Pendidikan & Kontak Darurat
Fields: Pendidikan Terakhir, Nama Sekolah/Univ, Nama Kontak Darurat, Telepon Kontak Darurat

### Card 4 — Status (edit mode only)
Fields: Toggle Aktif/Alumni, Dibuat, Diperbarui

---

## Layout

- Single `<form>` wrapping all 4 cards, vertically stacked
- No sidebar — `FormGrid`/`FormColumn` removed (single-column layout)
- Submit / Cancel buttons at the bottom of the form (below last card)
- `FormPageTemplate` used without `tabs` prop — pass `content` prop instead OR render outside template

---

## What Does NOT Change

- All state variables unchanged
- `validate()` logic unchanged (name + email required)
- `handleSubmit()` logic unchanged
- Service calls unchanged
- Navigation after save unchanged

---

## Files Changed

| File | Change |
|------|--------|
| `web-dashboard/src/pages/Students/StudentFormPage.tsx` | Remove tabs prop, replace with FieldSection cards |

---

## Out of Scope

- No new fields
- No API changes
- No service changes
- No routing changes
