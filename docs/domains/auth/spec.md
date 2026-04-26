# Design: Auth Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** RBAC authentication and authorization governing access across all VernonEdu domains

---

## Overview

Manages authentication and authorization for all VernonEdu users. Uses RBAC (Role-Based Access Control) to govern what each role can do across all domains. All routes and actions must route through RBAC — no per-domain hardcoded checks.

---

## Roles

| Role | Description |
|---|---|
| ceo | Full access; approves profit split overrides, extra revenue, certificate actions |
| finance | Adds extra revenue to batches (requires CEO approval) |
| academic_leader | Approves facilitator proposals (step 2); between CEO and dept_leader |
| dept_leader | Approves facilitators (step 1); assigns facilitators to classes; manages department |
| course_creator | Creates/manages own courses; proposes facilitators; maps facilitator tiers |
| vernonedu_admin | Manages system config: fee tiers, certificate types, vouchers, settings |
| admin | General admin: enrollment management, payment confirmation, budget realization, certificate actions |
| student | Enrolls in courses; views own dashboard, payments, certificates |
| franchisee | Read-only access to own branch revenue reports (no operational access) |

---

## Permission Matrix (by domain)

### Certificate
| Action | Who |
|---|---|
| Issue (auto) | System (on completion) |
| Issue (manual) | Admin → approval required |
| Request revoke/reissue | Admin |
| Approve revoke/reissue | Academic Leader / CEO |
| View public validator | Anyone (no login) |
| Download certificate | Student (own, profile complete) |
| Create / manage CertificateType | vernonedu_admin |

### Profit Split
| Action | Who |
|---|---|
| View split config | Admin, CEO, Finance |
| Override split per course | CEO only |
| Add extra revenue | Finance |
| Approve extra revenue | CEO |

### Payment
| Action | Who |
|---|---|
| Confirm bank transfer | Admin |
| Convert to installment | Admin |
| Process refund | Admin |
| View payment details | Admin, Student (own) |

### Budget
| Action | Who |
|---|---|
| Define course budget template | Course Creator (own courses), Admin |
| Add/edit batch budget items | Admin |
| Record realization | Admin only |
| View budget summary | Admin, Dept Leader, Course Creator (own courses) |

### Course
| Action | Who |
|---|---|
| Create/edit course | Course Creator (own), Admin |
| Create batch | Admin, Course Creator (own) |
| Set batch price | Admin |
| Approve batch open | Admin |

### Voucher
| Action | Who |
|---|---|
| Create/assign voucher | Admin, VernonEdu Admin |

### Module
| Action | Who |
|---|---|
| Create / edit module | Course Creator (own courses) |
| Publish module version | Course Creator (own courses) |
| Lock batch module version | Course Creator (own courses), Dept Leader |
| Access module content | Student (enrolled batches only) |

### Partner & PartnershipAgreement
| Action | Who |
|---|---|
| Create / edit Partner | Admin |
| Create / edit PartnershipAgreement | Admin |
| Activate agreement | Admin, CEO |
| Terminate agreement | CEO |
| Upload documents | Admin |
| View partner details | Admin, Finance, CEO |

### Franchise
| Action | Who |
|---|---|
| Create / manage Franchisee | Admin |
| Create / manage FranchiseAgreement | Admin, CEO |
| Add BranchOtherRevenue | Admin |
| Record royalty payment | Admin |
| View own branch revenue report | Franchisee (read-only, own branch) |
| View all franchise data | Admin, CEO, Finance |

### Team Member
| Action | Who |
|---|---|
| Create / edit TeamMember | vernonedu_admin, Admin |
| Deactivate TeamMember | vernonedu_admin |
| Create FacilitatorProfile | Admin, vernonedu_admin |
| Manage FeeTier table | vernonedu_admin |
| Propose facilitator | Course Creator (own courses only) |
| Approve proposal (step 1) | Dept Leader |
| Approve proposal (step 2) | Academic Leader |
| Assign facilitator to class | Dept Leader |

### Calendar
| Action | Who |
|---|---|
| Create manual event | Any internal staff |
| Edit / delete manual event | Event creator, Admin |
| View all events | Any internal staff |
| Manage own CalendarSync (Google OAuth) | Self only |
| Add attendee to event | Admin, Dept Leader |
| Auto-generated events (read-only) | System only |

### Notification
| Action | Who |
|---|---|
| Manage notification templates | vernonedu_admin |
| View delivery logs | Admin, vernonedu_admin |
| Manage own preferences | Any authenticated user (self only) |
| View others' preferences | Admin only |

### Enrollment
| Action | Who |
|---|---|
| Self-enroll via web (B2C) | Student |
| Create enrollment for B2B | Admin |
| Mark completion status | Admin |
| Drop enrollment | Admin |
| Convert payment to installment | Admin |

---

## Business Rules

1. All routes and actions protected by RBAC role checks — no per-domain hardcoding
2. Each role has defined permission scope; out-of-scope access denied
3. Approval chains (facilitator proposals, extra revenue, certificate actions) are multi-step and role-ordered
4. CEO has full access and can override any configurable value
5. `franchisee` role is read-only — no operational access
6. `student` only accesses own records (dashboard, payments, certificates)
7. Certificate download requires profile completion
8. Public certificate validator accessible without login

---

## Background Jobs

| — | — | — |

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `auth.user.created` | `{user_id, email, role}` | Notification |
| `auth.user.deactivated` | `{user_id}` | Team Member, Calendar, Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- All domains (auth governs access to every domain)
