# Domain: Module

## Overview

Courses are structured into ordered modules. Each module is versioned. Enrolled students access modules and their assets based on the batch's version policy — default is always latest published version, but Dept Leader or Course Creator can lock a batch to a specific version per module.

## Hierarchy

```
Course
  └── Module (ordered list)
        └── Module Version (versioned content)
              └── Module Asset (files, videos, links, etc.)

Course Batch
  └── Batch Module Config (optional per-module version override)
```

---

## Entities

### Module
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | Parent course |
| title | string | e.g., "Introduction to Python" |
| order | integer | Display order within the course |
| is_active | boolean | Inactive modules hidden from students |
| created_by | User | Course Creator |
| created_at | datetime | |

### Module Version
Each publish creates a new version. Only one version is `published` at a time per module.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| module | Module | |
| version_number | integer | Auto-incremented per module (1, 2, 3...) |
| title | string | Can differ per version |
| description | text | Module description / learning objectives |
| status | enum | draft, published, archived |
| published_at | datetime | Nullable |
| published_by | User | Nullable |
| created_by | User | Course Creator |
| created_at | datetime | |

### Module Asset
Resources attached to a module version.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| module_version | Module Version | Parent version |
| title | string | |
| asset_type | enum | video, pdf, document, link, image, other |
| url | string | File URL or external link |
| size_bytes | integer | Nullable; for uploaded files |
| order | integer | Display order within the module |
| is_downloadable | boolean | Whether student can download |
| created_by | User | |
| created_at | datetime | |

### Batch Module Config
Optional per-module version policy override for a batch. If not set, batch uses `auto_latest` default.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | Course Batch | |
| module | Module | Which module this config applies to |
| version_policy | enum | auto_latest, locked |
| locked_version | Module Version | Nullable; required if version_policy = locked |
| set_by | User | Dept Leader or Course Creator |
| updated_at | datetime | |

---

## Version Resolution (per student access)

```
For each module in the course:
  1. Check Batch Module Config for this batch + module
     → If config exists AND version_policy = locked:
         serve locked_version
     → If config exists AND version_policy = auto_latest:
         serve latest published version
     → If no config:
         serve latest published version (default)
```

---

## Student Access

Enrolled student can access all active modules of the course batch they enrolled in:
- Access granted when `enrollment.confirmed` fires, regardless of payment status. Students can access module content immediately after enrollment is confirmed.
- Access based on version resolution above
- Student sees: module title, description, assets (video/pdf/link/etc.)
- Download restricted per `is_downloadable` flag per asset

---

## Business Rules

1. Module order is explicit (`order` field) — Course Creator sets sequence
2. Only one Module Version can have `status = published` per module at a time
3. Publishing a new version auto-archives the previous published version
4. Default version policy is `auto_latest` — no config needed
5. Dept Leader or Course Creator can set `locked` policy per module per batch
6. `locked_version` must be a published version of the same module
7. Students in active batches see new version immediately when policy = `auto_latest`
8. Draft versions never visible to students — only published versions served
9. Inactive modules (`is_active = false`) hidden from all students
10. Assets inherit access from their module version — no per-asset enrollment check
11. Module access is **lifetime** — does not expire when batch closes
12. Which version student sees is still governed by Batch Module Config (auto_latest or locked) — lifetime access does not freeze the version unless policy = locked

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.confirmed` | Enrollment | Grant student access to all active modules of the enrolled Course Batch |

## Related Domains

- [course](../course/course.md)
- [enrollment](../enrollment/enrollment.md)
- [auth](../auth/auth.md)
