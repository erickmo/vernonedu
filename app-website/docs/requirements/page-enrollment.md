# Page: Enrollment

> Student enrollment flow — from batch selection to payment.

---

**Route:** `/daftar/:batchId`
**Title:** Pendaftaran

## Flow

```
Step 1: Review Batch  →  Step 2: Data Diri  →  Step 3: Pembayaran  →  Step 4: Konfirmasi
```

Stepper UI at top showing progress.

---

## Step 1: Review Batch

Display batch summary:
- Course name, type, batch code
- Schedule overview (dates, sessions count)
- Location / branch
- Facilitator
- Price + payment method options
- Seats remaining

**CTA:** "Lanjutkan Pendaftaran"

---

## Step 2: Data Diri

### If logged in (existing student)
- Pre-filled from student data
- Option to edit
- Referral code input (optional)

### If not logged in
- Registration form:

| Field | Type | Required |
|-------|------|----------|
| Nama Lengkap | text | ✅ |
| Email | email | ✅ |
| No Telepon | phone | ✅ |
| Tanggal Lahir | date | ❌ |
| Alamat | textarea | ❌ |
| Kode Referral | text | ❌ |

**CTA:** "Lanjutkan ke Pembayaran"

---

## Step 3: Pembayaran

Display payment method options (from batch config):
- Radio select payment method with explanation per method
- Show invoice preview (amount, due date, installment breakdown if scheduled)
- Payment instructions per method (transfer bank, etc.)

**CTA:** "Konfirmasi Pendaftaran"

---

## Step 4: Konfirmasi

Success page:
- ✅ "Pendaftaran Berhasil!"
- Summary: course, batch, schedule, payment info
- "Invoice akan dikirim ke email Anda"
- **CTA:** "Download App Siswa" (link to app stores) | "Lihat Kursus Lain"

---

## Referral Code Handling

If referral code is submitted:
- Validate code via API
- Show referral partner name ("Direferensikan oleh: [partner name]")
- On enrollment completion → triggers marketing partner commission (auto-payable)

---

**Last Updated:** Maret 2026
