# Siswa Detail Screen — Layout Spec

> Student detail / dashboard screen.

---

**Route:** `/students/:studentId`

## Header

- **Breadcrumb:** Siswa → [Student Name]
- **Title:** [Student Name] — [Email]
- **Subtitle:** [Phone Number]
- **Action:** `Edit` button → navigates to Siswa Form Screen (mode: Edit)

## Student Metadata Card

Card with student avatar and key metadata:
- Name, email, phone, student code
- Status (active/inactive/graduated)
- Department, enrollment date
- Talent Pool status (if enrolled in talent pool, show badge/indicator)

## Number Card Section

3 number cards in a row:

| Card | Value |
|------|-------|
| Total Course (Course Batch) | count |
| Total Course (Course Batch) Selesai | count |
| Total Course (Course Batch) Berjalan | count |

## Card: Riwayat Course

**Table:**

| Course | Batch | Waktu Lulus | Nilai | Link Sertifikat |
|--------|-------|-------------|-------|-----------------|
| [course name] | [batch code] | [completion date] | [score/grade] | [certificate link or —] |

---

## Card: Rekomendasi Course Berikutnya

Recommendations based on completed courses that have follow-up/next courses.

**Table:**

| Course | Reason |
|--------|--------|
| [recommended course name] | Lanjutan dari [completed course name] |

---

## Card: Notes

Comment-style notes section (similar to a comment thread):
- Each note shows: author name, date, content
- Can be added by: **Dept Leader** / **Operational Leader**
- Add note form at the bottom (text input + submit)

```
┌─────────────────────────────────────┐
│ [Author Name]          [Date]       │
│ [Note content]                      │
├─────────────────────────────────────┤
│ [Author Name]          [Date]       │
│ [Note content]                      │
├─────────────────────────────────────┤
│ [Text input: Tambah catatan...]     │
│                         [Kirim]     │
└─────────────────────────────────────┘
```

---

## Card: CRM Log

Log of CRM interactions with this student.

**Table:**

| Tanggal | Contacted By | Contact | Response |
|---------|-------------|---------|----------|
| [date] | [staff name] | [phone/email/whatsapp] | [response summary] |

---

## API Requirements

```
# CRM Log per Student
GET    /students/:id/crm-logs          → list of CRM interactions
POST   /students/:id/crm-logs          body: {contactMethod, response, contactedBy?}

# Notes (existing, verify access control)
GET    /students/:id/notes             → already exists
POST   /students/:id/notes             body: {content} — restrict to Dept Leader / Op Leader
```

---

**Last Updated:** Maret 2026
