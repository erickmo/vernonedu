# Finance Automation Hooks — Spec

> All automated triggers that create financial entries in the system.

---

## Overview

The finance module uses event-driven hooks to automatically create journal entries, invoices, and payables. These hooks listen to domain events and create the corresponding financial records without manual intervention.

---

## Auto-Invoice Creation

| # | Trigger Event | Invoice Created | Details |
|---|--------------|-----------------|---------|
| 1 | `EnrollmentCreatedEvent` (upfront) | 1 invoice, full amount | Due before class start |
| 2 | `EnrollmentCreatedEvent` (scheduled) | N invoices per schedule | Due dates per installment |
| 3 | `EnrollmentCreatedEvent` (batch_lump) | 1 invoice to client company | Full batch amount |
| 4 | Month start (monthly method) | 1 invoice per enrolled student | Based on sessions that month |
| 5 | `AttendanceSubmittedEvent` (per_session) | 1 invoice per attended session | After each session attended |

### Journal Entry (per invoice)
```
Debit:  1103 Piutang Usaha          Rp [amount]
Credit: 4001 Pendapatan Kursus      Rp [amount]
```

### On Payment Received
```
Debit:  1101 Kas / 1102 Bank        Rp [amount]
Credit: 1103 Piutang Usaha          Rp [amount]
```

---

## Auto-Payable: Facilitator

| Trigger | Payable Created |
|---------|----------------|
| `AttendanceSubmittedEvent` (facilitator completes session) | AP to facilitator based on level fee |

### Calculation
- Fee = facilitator level fee per session (max 2 hours, configured in settings)
- Created per session, not per batch

### Journal Entry
```
Debit:  5001 Biaya Fasilitator      Rp [fee]
Credit: 2100 Hutang Fasilitator     Rp [fee]
```

---

## Auto-Payable: Course Creator Commission

| Trigger | Payable Created |
|---------|----------------|
| Batch period closes / batch completes | AP to course creator |

### Calculation
- Basis: % of batch **profit** or **gross revenue** (per company settings)
- Calculated at batch completion or period close (monthly/quarterly — configurable)

### Journal Entry
```
Debit:  5002 Beban Komisi Course Creator    Rp [amount]
Credit: 2201 Hutang Komisi Course Creator   Rp [amount]
```

---

## Auto-Payable: Dept Leader Commission

| Trigger | Payable Created |
|---------|----------------|
| Batch period closes / batch completes | AP to dept leader |

### Calculation
- Basis: % of batch **profit** or **gross revenue** (per company settings)
- Scope: all batches under dept leader's department

### Journal Entry
```
Debit:  5003 Beban Komisi Dept Leader       Rp [amount]
Credit: 2202 Hutang Komisi Dept Leader      Rp [amount]
```

---

## Auto-Payable: Operation Leader Commission

| Trigger | Payable Created |
|---------|----------------|
| Batch period closes / batch completes | AP to operation leader |

### Calculation
- Basis: % of batch **profit** or **gross revenue** (per company settings)

### Journal Entry
```
Debit:  5004 Beban Komisi Op Leader         Rp [amount]
Credit: 2203 Hutang Komisi Op Leader        Rp [amount]
```

---

## Auto-Payable: Marketing Partner (Referral)

| Trigger | Payable Created |
|---------|----------------|
| `EnrollmentCreatedEvent` where student has referral code | AP to marketing partner |

### Calculation
- Commission per partner agreement: % of enrollment fee OR fixed amount per enrollment

### Journal Entry
```
Debit:  5005 Beban Komisi Marketing Partner Rp [amount]
Credit: 2204 Hutang Komisi Marketing Partner Rp [amount]
```

---

## Auto-Payable: On Payment (settling payables)

When accounting staff marks a payable as paid:

### Journal Entry
```
Debit:  2xxx Hutang [relevant account]      Rp [amount]
Credit: 1101 Kas / 1102 Bank               Rp [amount]
```

---

## Event-to-Hook Mapping Summary

| Domain Event | Finance Hook(s) |
|-------------|-----------------|
| `EnrollmentCreatedEvent` | Create invoice(s) + journal entry. If referral → create marketing partner AP |
| `AttendanceSubmittedEvent` | Create facilitator AP + journal entry. If per_session → create student invoice |
| `BatchCompletedEvent` | Create commission APs (course creator, dept leader, op leader) + journal entries |
| `InvoicePaidEvent` | Journal entry (cash/bank debit, piutang credit) |
| `PayablePaidEvent` | Journal entry (hutang debit, cash/bank credit) |
| `MonthStartEvent` (scheduled) | Create monthly invoices for monthly-method batches |

---

## Settings Dependencies

These hooks depend on company settings (Director access):

| Setting | Used By |
|---------|---------|
| Facilitator levels + fee per session | Facilitator AP calculation |
| Commission % + basis (profit/revenue) for Op Leader | Op Leader AP |
| Commission % + basis for Dept Leader | Dept Leader AP |
| Commission % + basis for Course Creator | Course Creator AP |
| Referral partner commission (% or fixed) | Marketing Partner AP |
| Chart of Accounts (preset, seeded) | All journal entries |

---

**Last Updated:** Maret 2026
