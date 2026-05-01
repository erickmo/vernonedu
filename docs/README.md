# VernonEdu — Project Documentation

## Overview

VernonEdu is an informal education institution offering courses, programs, seminars, and workshops. Operates both B2B (partner partnerships) and B2C (direct students).

---

## Business Model

### B2B — Partner Partnerships

VernonEdu partners with schools and universities to deliver:

- **Standard courses** — existing catalog offered to partner's students
- **Custom programs** — tailored curriculum designed per partner's needs
- **Seminars & workshops** — one-time or recurring events

**Payment structures:**
| Model | Description |
|---|---|
| Per visit | Partner pays per session/visit |
| Per course | Fixed fee per course delivered |
| Per student | Bulk rate × enrolled student count |

Payment payer can be **partner** OR **individual students**, depending on negotiation.

---

### B2C — Direct Students

Students enroll independently with two class formats:

| Format | Description |
|---|---|
| Regular class | Group sessions, lower price point |
| Private class | 1-on-1 or small group, premium pricing |

**Delivery mode:**
| Mode | Description |
|---|---|
| Online | Remote via platform |
| Offline | In-person at venue |

**Important constraints:**
- Not every course offers both Regular and Private formats
- Not every course is available in both Online and Offline mode
- Availability per course must be explicitly configured

---

### Franchise Model

VernonEdu operates a franchise system where:

- **Franchisee** owns the location/branch
- **VernonEdu retains 100% operational management** — curriculum, instructors, scheduling, quality control
- Franchisee role is investor/location owner, not operator

**Revenue Split Model:**

Each franchisee has individually negotiated terms stored on the franchise record:

| Component | Type | Configured per franchisee |
|---|---|---|
| Buy-in fee | One-time | Yes |
| Monthly royalty | Fixed recurring | Yes |
| Revenue royalty | % of gross revenue | Yes |

All three components are set at franchise agreement level — no global default.

**Implication on business model:**
- B2B and B2C operations at franchise branches follow the same rules as HQ
- All enrollments, courses, and pricing governed by VernonEdu, not franchisee
- Royalty tracking requires per-branch revenue reporting

---

## Course Structure

### Hierarchy

```
Department
  └── Course
        ├── Course Creator (assigned per course)
        └── Course Batch
              └── Class (one or more sessions)
```

- **Department** — top-level grouping, led by a Department Leader
- **Course** — belongs to one department, has one Course Creator
- **Course Batch** — a scheduled run of the course; students enroll at this level
- **Class** — individual sessions within a batch

---

### Roles in Course Delivery

| Role | Description |
|---|---|
| Course Creator | Owns the course content; can teach classes directly |
| Facilitator | Teaches classes on behalf of Course Creator |
| Department Leader (Dept Leader) | Approves facilitators and facilitator tier assignments |
| Academic Leader | Role between CEO and Dept Leader; approves facilitators |
| CEO | Highest authority; can override profit split per course |

---

### Profit Split

Default split configured in **VernonEdu global settings**:

| Party | Share |
|---|---|
| VernonEdu | % (configurable) |
| Course Creator | % (configurable) |
| Department Leader | % (configurable) |

**Override rule:** CEO can override split per individual course. Department/global defaults apply otherwise.

---

### Facilitators

**Who can teach a class:**
- Course Creator (directly), OR
- Approved Facilitator

**Facilitator proposal & approval flow:**

```
Course Creator proposes facilitator
  → Dept Leader approves
  → Academic Leader approves
  → Facilitator is active for that course
```

Approval is **sequential**: Dept Leader must approve before Academic Leader can review.

---

### Facilitator Fee Tiers

Fee is tiered and can be set **per class**, **per course**, or both — configured per facilitator assignment:

| Who | Responsibility |
|---|---|
| Academic Leader / CEO | Defines the fee tier table (tier names + amounts) |
| Course Creator | Assigns a tier to each facilitator per course |
| Dept Leader | Approves the tier assignment |

**Flow:**
```
Academic Leader / CEO sets tier table (e.g., Tier A = Rp X, Tier B = Rp Y)
  → Course Creator picks tier for each facilitator on each course
  → Dept Leader approves the tier assignment
```

Course Creator cannot set custom amounts — only selects from predefined tiers.

---

## Key Entities

```
Partner (school / university)
  └── PartnershipAgreement
        ├── Payment model (per-visit / per-course / per-student)
        ├── Payer (partner | student)
        └── Programs offered

Course
  ├── Format availability: regular | private | inhouse_training | inschool_program
  ├── Mode availability: online | offline | both
  └── Pricing (per format, per mode)

Student
  ├── Source: B2B (via partner) | B2C (direct)
  ├── Enrollment → Course
  │     ├── Format: regular | private
  │     └── Mode: online | offline
  └── Payment

Enrollment
  ├── Student
  ├── Course
  ├── Format (regular | private)
  ├── Mode (online | offline)
  ├── Payer (student | partner)
  └── Payment status
```

---

## Business Rules

1. **Course format constraint** — enrollment must check if chosen format (regular/private) is enabled for that course
2. **Course mode constraint** — enrollment must check if chosen mode (online/offline) is enabled for that course
3. **B2B payer resolution** — payer determined by PartnershipAgreement, not per-enrollment
4. **B2B bulk pricing** — price may differ from standard catalog; stored on the agreement level
5. **B2C pricing** — price varies by: course × format × mode

---

## Glossary

| Term | Meaning |
|---|---|
| Partner | School or university in B2B partnership |
| PartnershipAgreement | Agreement between VernonEdu and a partner |
| Regular class | Group format, standard pricing |
| Private class | 1-on-1 format, premium pricing |
| Online | Remote delivery |
| Offline | In-person delivery |
| Per-visit | Payment per session/visit by partner |
| Payer | Who pays: partner or student |
