# Domain: Auth

## Overview

Manages authentication and authorization for all VernonEdu users. Uses RBAC (Role-Based Access Control) to govern what each role can do across all domains.

> **TODO:** Refactor authorization in older domains to reference this auth domain. All permission checks should route through RBAC, not be hardcoded per domain.

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

### Facilitator
| Action | Who |
|---|---|
| Propose facilitator | Course Creator (own courses only) |
| Assign fee tier | Course Creator (own courses only) |
| Approve proposal (step 1) | Dept Leader |
| Approve proposal (step 2) | Academic Leader |
| Assign facilitator to class | Dept Leader |
| Manage fee tier table | VernonEdu Admin |

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
| Add/edit batch budget items | Admin |
| Record realization | Admin only |
| View budget summary | Admin, Dept Leader |

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

---

## TODO: Auth Refactor

- [ ] Audit all domain docs — replace ad-hoc role mentions with reference to this auth domain
- [ ] Implement RBAC middleware in backend (all routes protected by role check)
- [ ] Define approval chains as configurable workflows (not hardcoded)
- [ ] Add audit log for all approved/rejected actions (who, when, what)
- [ ] Review franchisee portal access scope

---

## Related Domains

- All domains (auth governs access to every domain)
