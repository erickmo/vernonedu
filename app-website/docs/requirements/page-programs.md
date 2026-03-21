# Pages: Program

> Individual program type pages — each sells a specific course type.

---

## Common Layout (all program pages)

Each program page follows the same template with content tailored per type:

1. **Hero Section** — program name, tagline, hero image, CTA "Lihat Kursus"
2. **What You Get** — 3-4 benefit cards with icons
3. **How It Works** — step-by-step flow specific to this program type
4. **Available Courses** — dynamic from API, filtered by this course type
5. **Pricing** — price range info + "Mulai dari Rp X"
6. **Testimonials** — filtered to this program type
7. **FAQ** — program-specific FAQ accordion
8. **CTA** — "Daftar Sekarang" banner

---

## Program Karir

**Route:** `/program/karir`
**Tagline:** "Belajar, Magang, Berkarir"

**Unique sections:**
- **Pipeline visual:** Learning → Internship → Talent Pool → Career (horizontal timeline graphic)
- **Talent Pool highlight:** "Bergabung dengan talent pool VernonEdu dan terhubung dengan X+ perusahaan partner"
- **Partner logos** section (hiring companies)
- **Certification:** Certificate of Participant + Certificate of Competency explained

**Available courses:** Filter `course_type = program_karir`

---

## Kursus Reguler

**Route:** `/program/reguler`
**Tagline:** "Kuasai Skill Baru dengan Jadwal Fleksibel"

**Unique sections:**
- **Flexible schedule** highlight — variety of batch schedules
- **Payment options** — show available payment methods
- **Certificate of Participant** on completion

**Available courses:** Filter `course_type = reguler`

---

## Kursus Privat

**Route:** `/program/privat`
**Tagline:** "Belajar 1-on-1 Sesuai Kebutuhanmu"

**Unique sections:**
- **Custom pace** — learn at your own speed
- **Flexible pricing** — per session option highlighted
- **Direct facilitator** access

**Available courses:** Filter `course_type = privat`

---

## Sertifikasi

**Route:** `/program/sertifikasi`
**Tagline:** "Buktikan Kompetensimu dengan Sertifikat Resmi"

**Unique sections:**
- **Two certificate types** explained: Participant vs Competency
- **Test-only option** — "Sudah punya skill? Langsung ikut ujian sertifikasi tanpa kursus"
- **QR verification** — "Setiap sertifikat bisa diverifikasi online"
- **Eligibility criteria** per course

**CTA variation:** "Daftar Ujian Sertifikasi" alongside "Ikut Kursus + Sertifikasi"

---

**Last Updated:** Maret 2026
