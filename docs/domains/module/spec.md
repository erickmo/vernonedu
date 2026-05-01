# Design: Module Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Versioned course content modules with batch-level version locking

---

## Overview

Courses structured into ordered modules. Each module versioned. Enrolled students access modules per batch's version policy — default is auto-latest, with optional per-module lock.

---

## Hierarchy

```
Course
  └── Module (ordered list)
        └── ModuleVersion (versioned content)
              └── ModuleAsset (files, videos, links)

CourseBatch
  └── BatchModuleConfig (optional per-module version override)
```

---

## Entities

### Module
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | |
| title | string | |
| order | integer | Display order |
| is_active | boolean | Inactive hidden from students |
| created_by | User | Course Creator |
| created_at | datetime | |

### ModuleVersion
One published per module at a time.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| module | Module | |
| version_number | integer | Auto-incremented per module |
| title | string | Can differ per version |
| description | text | Learning objectives |
| status | enum | draft, published, archived |
| published_at | datetime | Nullable |
| published_by | User | Nullable |
| created_by | User | |
| created_at | datetime | |

### ModuleAsset
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| module_version | ModuleVersion | |
| title | string | |
| asset_type | enum | video, pdf, document, link, image, other |
| url | string | |
| size_bytes | integer | Nullable |
| order | integer | |
| is_downloadable | boolean | |
| created_by | User | |
| created_at | datetime | |

### BatchModuleConfig
Per-module version policy override per batch. Default if absent: `auto_latest`.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | CourseBatch | |
| module | Module | |
| version_policy | enum | auto_latest, locked |
| locked_version | ModuleVersion | Nullable; required if locked |
| set_by | User | Dept Leader or Course Creator |
| updated_at | datetime | |

---

## Version Resolution

```
For each module in course:
  Check BatchModuleConfig for this batch + module
    → exists AND locked → serve locked_version
    → exists AND auto_latest → latest published
    → no config → latest published (default)
```

---

## Student Access

- Granted on `enrollment.confirmed`, regardless of payment status
- Module access is **lifetime** — does not expire when batch closes
- Version still governed by BatchModuleConfig (lifetime ≠ frozen unless locked)
- Sees: module title, description, assets
- Download per `is_downloadable`

---

## Business Rules

1. Module order explicit (`order` field)
2. Only one published ModuleVersion per module at a time
3. Publishing new version auto-archives previous published
4. Default policy = `auto_latest`
5. Dept Leader or Course Creator sets `locked` per module per batch
6. `locked_version` must be a published version of same module
7. `auto_latest` students see new versions immediately
8. Drafts never visible to students
9. Inactive modules hidden
10. Asset access inherits module access — no per-asset enrollment check
11. Lifetime access; version frozen only if policy = locked

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
| `enrollment.confirmed` | Enrollment | Grant student access to all active modules of enrolled batch |

---

## Related Domains

- [course](../course/course.md)
- [enrollment](../enrollment/enrollment.md)
- [auth](../auth/auth.md)
