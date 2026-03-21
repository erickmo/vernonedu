# Page: Verifikasi Sertifikat

> Public certificate verification via QR code or manual code input.

---

**Route:** `/sertifikat/:code` (from QR scan) or `/sertifikat` (manual input)

## If no code (manual input)

- Title: "Verifikasi Sertifikat"
- Input field: "Masukkan kode sertifikat"
- Button: "Verifikasi"

## If valid certificate

Display:
- ✅ "Sertifikat Valid"
- Certificate holder name
- Course name
- Certificate type (Participant / Competency)
- Issue date
- Certificate number
- Issuing branch

## If revoked certificate

Display:
- ❌ "Sertifikat Dicabut"
- Same info as above
- **Watermark overlay: "SERTIFIKAT DICABUT"**
- Revocation reason (if public)

## If invalid code

- ❌ "Sertifikat Tidak Ditemukan"
- "Pastikan kode yang dimasukkan sudah benar"

---

**Last Updated:** Maret 2026
