# Design: Department Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Top-level organizational unit grouping courses; led by Department Leader

---

## Overview

Top-level organizational unit. Each department groups related courses and is led by a Department Leader who approves facilitators (step 1 of 2) and receives a department share of profit.

---

## Hierarchy Position

```
Department
  └── Course
        └── Course Batch
              └── Class
```

---

## Entities

### Department
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | |
| leader | User (dept_leader) | One leader per department; same user may lead multiple |
| is_active | boolean | Inactive depts hidden from course creation |
| created_by | User | |
| created_at | datetime | |

---

## Roles

| Role | Scope |
|---|---|
| Department Leader | Manages 1+ departments; approves facilitators and tier assignments |

---

## Business Rules

1. Each course belongs to exactly one department
2. Each department has exactly one leader; a User with role `dept_leader` may lead multiple departments
3. Dept Leader is first approver in facilitator approval chain
4. Dept Leader profit share configured globally; CEO can override per course

---

## Background Jobs

| — | — | — |

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- [course](../course/course.md)
- [team-member](../team-member/team-member.md)
- [profit-split](../profit-split/profit-split.md)
