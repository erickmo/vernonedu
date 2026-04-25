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
| name | string | Department name |
| leader | User (role: dept_leader) | One leader per department; same User can lead multiple departments |

## Roles

| Role | Scope |
|---|---|
| Department Leader | Manages one or more departments; approves facilitators and tier assignments |

## Business Rules

1. Each course belongs to exactly one department
2. Each department has exactly one leader (dept_leader), but a single User with role dept_leader may lead multiple departments
3. Dept Leader is the first approver in the facilitator approval chain
4. Dept Leader share of profit is configured globally but can be overridden per course by CEO

## Related Domains

- [course](../course/course.md)
- [facilitator](../facilitator/facilitator.md)
- [profit-split](../profit-split/profit-split.md)
