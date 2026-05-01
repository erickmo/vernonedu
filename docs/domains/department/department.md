# Domain: Department

## Overview

Top-level organizational unit in VernonEdu's course hierarchy. Each department groups related courses and is led by a Department Leader.

## Hierarchy Position

```
Department
  └── Course
        └── Course Batch
              └── Class
```

## Responsibilities

- Groups courses by subject area or discipline
- Department Leader approves facilitators (step 1 of 2 in approval chain)
- Department Leader approves facilitator tier assignments
- Department Leader receives a share of course revenue (see profit-split domain)

## Entities

### Department
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string | Department name |
| leader | User (role: dept_leader) | One leader per department; same User can lead multiple departments |
| is_active | boolean | Inactive departments hidden from course creation |
| created_by | User | |
| created_at | datetime | |

## Roles

| Role | Scope |
|---|---|
| Department Leader | Manages one or more departments; approves facilitators and tier assignments |

## Business Rules

1. Each course belongs to exactly one department
2. Each department has exactly one leader (dept_leader), but a single User with role dept_leader may lead multiple departments
3. Dept Leader is the first approver in the facilitator approval chain
4. Dept Leader share of profit is configured globally but can be overridden per course by CEO

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

## Related Domains

- [course](../course/course.md)
- [team-member](../team-member/team-member.md)
- [profit-split](../profit-split/profit-split.md)
