# Marketing Screen — Layout Spec

> Marketing management: statistics, leads, social media scheduling, PR, class documentation automation, partner program, and calendar.

---

**Route:** `/marketing`
**Title:** Marketing
**Subtitle:** Manajemen Pemasaran & Konten

---

## Section 1: Statistics

### Number Cards Row

| Card | Value |
|------|-------|
| Total Leads | count |
| Leads Bulan Ini | count (vs previous month %) |
| Konversi Lead → Siswa | percentage |
| Posting Terjadwal | count (upcoming) |
| Posting Selesai (bulan ini) | count |
| Partner Referral Aktif | count |

### Charts Row (2-column layout)

| Column 1 (1/2) | Column 2 (1/2) |
|-----------------|-----------------|
| **Line Chart:** Lead acquisition trend (monthly, last 6 months) | **Bar Chart:** Konversi per sumber lead (social media, referral, website, walk-in, etc.) |

### Additional Stat Cards Row

| Card | Value |
|------|-------|
| Total Pendapatan Referral (bulan ini) | amount |
| Course Batch Dipromosikan | count |
| Rata-rata Waktu Lead → Enrollment | days |

---

## Section 2: Leads

### Card: Lead Management

**Actions:**
- `+ Tambah Lead` button → add new lead form

**Filters:**
- Nama (text input)
- Status (dropdown: Baru / Dihubungi / Tertarik / Negosiasi / Enrolled / Tidak Tertarik)
- Sumber (dropdown: Social Media / Referral / Website / Walk-in / Partner / Lainnya)
- Interest / Course (dropdown)

**Table:** Pagination 15 per page

| Nama | Email / Telp | Sumber | Interest | Status | Terakhir Dihubungi | PIC |
|------|-------------|--------|----------|--------|-------------------|-----|
| [name] | [contact] | [source pill] | [course interest] | [status pill] | [date] | [staff name] |

**On row click:** Open lead detail with CRM log (links to student CRM log if converted)

### Lead Detail (expandable or modal)

- Lead metadata (name, contact, source, interest)
- **CRM Log Table:**

| Tanggal | Contacted By | Metode | Response | Follow-up |
|---------|-------------|--------|----------|-----------|
| [date] | [staff name] | [phone/email/WA] | [response] | [next action date] |

- `+ Tambah Log` button
- If lead converts → `Konversi ke Siswa` button → creates student record and links

---

## Section 3: Social Media Scheduling

### Card: Social Media Posts

**Actions:**
- `+ Jadwalkan Post` button → scheduling form

**Filters:**
- Platform (dropdown: Instagram / Facebook / TikTok / LinkedIn / Semua)
- Status (dropdown: Dijadwalkan / Diposting / Draft)
- Bulan (month picker)

**Table:** Pagination 15 per page

| Tanggal | Platform | Konten | Tipe | Status | URL Post |
|---------|----------|--------|------|--------|----------|
| [date + time] | [platform icon + name] | [content preview — max 1 line, truncate] | [promo / dokumentasi / info] | [status pill] | [link or —] |

### Scheduling Form (modal or separate)

| Field | Type | Notes |
|-------|------|-------|
| Platform | multi-select | Instagram, Facebook, TikTok, LinkedIn |
| Tanggal & Waktu | datetime picker | — |
| Tipe Konten | dropdown | Promosi Course / Dokumentasi Kelas / Info Umum / Event |
| Konten / Caption | textarea | — |
| Media / Attachment | file upload | Image or video |
| Course Batch (optional) | dropdown | Link to specific batch |

### Reporting: Submit Post URL

After posting, marketing team submits the actual post URL:
- Click row → `Submit URL` action
- Input: URL field
- Status changes from `Dijadwalkan` → `Diposting`

---

## Section 4: Class Documentation Auto-Scheduling

System automatically creates a posting schedule for class documentation:

### Rules
- **2 days after each class session**, a documentation post is auto-scheduled
- If the scheduled date falls on a **holiday**, add 1 more day (post on the next working day)
- Holiday calendar is configurable in settings

### Auto-Generated Entry
- Tipe: `Dokumentasi Kelas`
- Konten template: auto-filled with batch name, module, date of class
- Status: `Dijadwalkan` (marketing team reviews and can edit before posting)
- Marketing team posts → submits URL → status becomes `Diposting`

### Card: Dokumentasi Kelas Terjadwal

**Table:** Shows upcoming auto-scheduled documentation posts

| Tanggal Post | Kelas | Modul | Sesi Tanggal | Status | URL Post |
|-------------|-------|-------|-------------|--------|----------|
| [post date] | [batch name] | [module title] | [class date] | [status pill] | [link or —] |

---

## Section 5: PR Scheduling

### Card: PR & Event Schedule

**Actions:**
- `+ Jadwalkan PR` button

**Filters:**
- Status (dropdown: Dijadwalkan / Berjalan / Selesai)
- Tipe (dropdown: Press Release / Event / Sponsorship / Interview / Lainnya)

**Table:** Pagination 10 per page

| Tanggal | Judul | Tipe | Media / Venue | PIC | Status | Keterangan |
|---------|-------|------|--------------|-----|--------|------------|
| [date] | [title] | [type pill] | [media name or venue] | [staff name] | [status pill] | [notes — truncate] |

---

## Section 6: Marketing Partner Program (Referral)

Partners and individuals can earn commission by referring students using a referral code.

### Number Cards Row

| Card | Value |
|------|-------|
| Partner Referral Aktif | count |
| Total Referral Bulan Ini | count |
| Total Komisi Dibayar (bulan ini) | amount |
| Konversi Referral → Enrollment | percentage |

### Card: Referral Partner List

**Actions:**
- `+ Tambah Referral Partner` button

**Filters:**
- Nama (text input)
- Status (dropdown: Aktif / Tidak Aktif)

**Table:** Pagination 15 per page

| Nama Partner | Kode Referral | Total Referral | Enrolled | Komisi Total | Komisi Pending | Status |
|-------------|--------------|---------------|----------|-------------|---------------|--------|
| [name] | [code] | [count] | [count] | [amount] | [amount] | [status pill] |

**On row click:** Expand/modal showing:
- Partner detail
- Referral history table: Tanggal, Nama Lead, Course, Status, Komisi
- Commission settings (percentage or fixed per enrollment)

### Commission Configuration

Set in Settings (accessible by Director / Operation Leader):
- Commission type: percentage of enrollment fee OR fixed amount per enrollment
- Commission is auto-calculated and posted to accounting journal (see [accounting.md](accounting.md))

---

## Section 7: Calendar

### Card: Marketing Calendar

Full calendar view (month view default, can switch to week):
- **Color-coded events:**
  - 🔵 Social media post scheduled
  - 🟢 Social media post completed (has URL)
  - 🟠 PR / Event scheduled
  - 🟣 Class documentation auto-scheduled
  - ⚪ Holiday (from holiday calendar settings)
- Click on event → opens detail / edit
- Click on empty date → quick-add scheduling form

---

## API Requirements (from screen specs)

```
# Leads
GET    /leads                     ?offset, limit, status?, source?, interest?
GET    /leads/:id
POST   /leads                     body: {name, email?, phone?, source, interest?, notes?}
PUT    /leads/:id
DELETE /leads/:id
POST   /leads/:id/convert         → converts lead to student

# Lead CRM Log
GET    /leads/:id/crm-logs
POST   /leads/:id/crm-logs        body: {contactMethod, response, followUpDate?}

# Social Media Scheduling
GET    /marketing/posts            ?platform?, status?, month?
GET    /marketing/posts/:id
POST   /marketing/posts            body: {platforms[], scheduledAt, contentType, caption, media?, batchId?}
PUT    /marketing/posts/:id
PUT    /marketing/posts/:id/submit-url   body: {url}
DELETE /marketing/posts/:id

# Auto-scheduled Documentation
GET    /marketing/class-docs       ?status?  → list of auto-generated doc posts

# PR Scheduling
GET    /marketing/pr               ?status?, type?
POST   /marketing/pr               body: {title, type, scheduledAt, mediaVenue?, pic?, notes?}
PUT    /marketing/pr/:id
DELETE /marketing/pr/:id

# Referral Partner Program
GET    /marketing/referral-partners         ?status?
GET    /marketing/referral-partners/:id
POST   /marketing/referral-partners         body: {name, contactEmail?, commissionType, commissionValue}
PUT    /marketing/referral-partners/:id
GET    /marketing/referral-partners/:id/referrals   → referral history

# Holiday Calendar (for documentation auto-scheduling)
GET    /settings/holidays          ?year=2026
POST   /settings/holidays          body: {date, name}
DELETE /settings/holidays/:id
```

---

**Last Updated:** Maret 2026
