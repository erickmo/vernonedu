# Partner Detail Screen — Layout Spec

> Partner detail with MOU tracking and partnership log.

---

**Route:** `/business-development/partners/:partnerId`

## Header

- **Breadcrumb:** Business Development → Partners → [Partner Name]
- **Title:** Partner: [Partner Name]

## Card: Partnership Detail

Partner description and metadata:
- Name, industry, address, contact info
- Group Partner
- Status (prospect / contacted / negotiating / active / inactive)
- Partner since date
- Website, logo

## Card: MOU

**Table:**

| Nomor Surat | Tanggal MoU | Tanggal Berakhir MoU |
|-------------|-------------|---------------------|
| [document number] | [start date] | [end date — highlight if expiring within 3 months] |

**Action:** `+ Tambah MoU` button

---

## Card: Partnership Log

Log of projects and collaborations with this partner.

**Table:**

| Tanggal | Project / Batch | Tipe | Status | Keterangan |
|---------|----------------|------|--------|------------|
| [date] | [project/batch name] | [project / kolaborasi / inhouse] | [status] | [notes] |

---

**Last Updated:** Maret 2026
