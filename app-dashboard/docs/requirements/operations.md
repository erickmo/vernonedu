# Domain: Operations

> Location management (buildings & rooms with facilities), ads template system, website visibility, leads management, and operational dashboard.

---

## Location Management

### Hierarchy

```
Building
  └──< Room
         ├── facilities[] (projector, whiteboard, AC, computers, etc.)
         └──< Schedule (linked to batch session)
```

### Room Facilities
Each room stores a list of available facilities (e.g. projector, whiteboard, AC, computers, speaker system). This makes it easier for course planners to **allocate the right room** for each class based on module requirements.

### Features
- CRUD for buildings and rooms (including facility list per room)
- Room availability checking when creating/editing batch schedules
- **Facility matching** — when scheduling, suggest rooms that match module tool requirements
- **Conflict detection:** same room, overlapping time → blocked by default
- Overlap exception: can be approved by Operational Leader (approval workflow #9)

### Routes

```
/locations     → LocationPage (buildings & rooms management)
```

### API Endpoints (planned)

```
# Buildings
GET    /buildings              ?offset, limit
GET    /buildings/:id
POST   /buildings              body: {name, address?, description?}
PUT    /buildings/:id
DELETE /buildings/:id

# Rooms
GET    /rooms                  ?building_id=:id
GET    /rooms/:id
POST   /rooms                  body: {buildingId, name, capacity?, floor?, facilities[], description?}
PUT    /rooms/:id
DELETE /rooms/:id

# Availability check
GET    /rooms/:id/availability ?from=datetime&to=datetime
```

---

## Module Tools & Requirements

Each CourseModule (which maps to class schedules) includes a list of **tools and requirements** needed for that session. This enables:
- Operational team to prepare materials/tools before class
- Room allocation matching (room facilities vs module requirements)
- Dashboard view of what to prepare

See [curriculum.md](curriculum.md) for CourseModule entity details.

---

## Leads Management

Operation team inputs **potential leads** (prospective students/clients) into the system:
- When a new course or course batch is created, the system cross-references leads data to identify **potential customers**
- Leads can be tagged by interest area, source, status
- Helps Marketing and CS teams with targeted outreach

### API Endpoints (planned)

```
GET    /leads              ?offset, limit, status?, interest?
GET    /leads/:id
POST   /leads              body: {name, email?, phone?, interest?, source?, notes?}
PUT    /leads/:id
DELETE /leads/:id
```

---

## Operational Dashboard

The **dashboard for the operational team** shows:

### Today View
- What to prepare for **today's classes**: room setup, tools/materials per module, facilitator info
- Any schedule conflicts or issues

### 7-Day View
- **Day-by-day layout** of upcoming schedules for the next 7 days
- Each day shows: batch name, module, room, facilitator, tools needed, student count
- Highlights items that need attention (missing facilitator, room not confirmed, tools not prepared)

---

## Ads Template System

- Each course has a **default ads template** managed by Marketing Team
- When a course or course batch is updated, the system **auto-edits** the ads template to reflect the latest information (pricing, schedule, etc.)
- Marketing Team can further customize templates

### Workflow
1. Course created → system generates default ads template
2. Course batch created/updated → system updates relevant template fields
3. Marketing Team reviews and publishes

---

## Website Visibility

- Each course batch has a `website_visible` toggle
- Default: **displayed** (true)
- Op Admin or Course Creator can toggle visibility
- When visible, batch appears on `app-website` and is open for enrollment

---

## Status

🔴 Not implemented — all features are new for v2.
