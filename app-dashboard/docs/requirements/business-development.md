# Domain: Business Development

> Strategic planning, franchise management, partnership tracking, OKR/KPI, investment planning, financial projections, and delegation.

---

## Overview

Business Development is a Director-level domain covering:
1. **Business Model Canvas** — full BMC with live partner tracking
2. **Branch & Franchise Management** — manage VernonEdu locations
3. **OKR & KPI** — organizational goal tracking cascaded by role
4. **Investment Plan** — capital planning and tracking
5. **Financial Projections** — potential cash, revenue, profit/loss reports
6. **Delegation** — request/assign projects and courses to teams

---

## Business Model Canvas (BMC)

Full Business Model Canvas with 9 components:

| # | Component | Special Behavior |
|---|-----------|-----------------|
| 1 | Key Partners | Links to Partner domain — track partnership progress, potential partners |
| 2 | Key Activities | — |
| 3 | Key Resources | — |
| 4 | Value Propositions | — |
| 5 | Customer Relationships | — |
| 6 | Channels | — |
| 7 | Customer Segments | Links to Leads + Student data |
| 8 | Cost Structure | Links to Accounting (expense categories) |
| 9 | Revenue Streams | Links to Accounting (revenue categories) |

### Partner Tracking (within BMC)
- List partners and **potential partners**
- Track partnership progress/stage: `prospect → contacted → negotiating → active → inactive`
- Links to Partner & MOU domain (see [future.md](future.md)) for formal MOU management
- Dashboard view of partnership pipeline

---

## Branch & Franchise Management

VernonEdu operates as a franchise. This module manages:

### Branch
- CRUD for branches (name, address, city, region, contact, status)
- Each branch has its own: CoA instance, transactions, reports, staff assignments
- Branch status: `active | inactive | pending_setup`

### Franchise
- Franchise agreements with external operators
- Agreement terms: duration, fees, territory, obligations
- Track franchise performance (revenue, student count, compliance)
- Franchise status: `prospect → negotiating → active → suspended → terminated`

### API Endpoints (planned)

```
# Branches
GET    /branches              ?offset, limit, status?
GET    /branches/:id
POST   /branches              body: {name, address, city, region, contactName, contactPhone}
PUT    /branches/:id
DELETE /branches/:id

# Franchises
GET    /franchises             ?offset, limit, status?
GET    /franchises/:id
POST   /franchises             body: {partnerName, territory, startDate, endDate, feeStructure, ...}
PUT    /franchises/:id
```

---

## OKR & KPI Management

Organizational objectives cascaded by level:

### Hierarchy
```
Company OKR (Director)
  └──< Department OKR (Education Leader / Operation Leader / Accounting Leader)
         └──< Team OKR (Dept Leader, Course Owner, etc.)
                └──< Individual KPI (per employee)
```

### Features
- Create Objectives with measurable Key Results
- Set target values and track progress (% completion)
- Time-bound: quarterly or annual periods
- Cascade: company → department → team → individual
- Dashboard: progress tracking per level, red/yellow/green status
- Link KPIs to actual system data where possible (e.g. enrollment count, revenue, attendance rate)

### Entities (planned)

| Entity | Key Fields |
|--------|------------|
| ObjectiveEntity | id, parentId?, title, description, ownerId, ownerRole, period (Q1-2026, etc.), status, progress% |
| KeyResultEntity | id, objectiveId, title, targetValue, currentValue, unit, status |
| KpiEntity | id, employeeId, title, targetValue, currentValue, unit, period, linkedMetric? |

---

## Investment Plan

Capital planning and tracking for VernonEdu growth:

### Features
- Create investment proposals (new branch, equipment, technology, marketing campaign)
- Each proposal: amount, expected ROI, timeline, status
- Track actual spending vs planned investment
- Link to Accounting (capital expense tracking)
- Approval: proposed by any leader → approved by Director

### Entities (planned)

| Entity | Key Fields |
|--------|------------|
| InvestmentPlanEntity | id, title, description, category, proposedBy, amount, expectedRoi, startDate, endDate, status (draft\|proposed\|approved\|in_progress\|completed\|cancelled), actualSpend |

---

## Financial Projection Reports

Auto-generated projection reports based on current data + planned activities:

### Reports Available

| Report | Description | Data Sources |
|--------|-------------|-------------|
| Potential Monthly Cash | Projected cash position for next 1–12 months | Current cash + expected enrollment revenue − planned expenses − commission |
| Potential Profit/Loss | Projected P&L per branch and consolidated | Revenue projections (from batch pricing × expected enrollment) − cost projections |
| Potential Revenue | Projected revenue breakdown | Active batches × pricing × enrollment rate, pipeline from Leads |
| Revenue Forecast | Forward-looking revenue based on upcoming batches | Approved batches not yet started + active batches remaining sessions |
| Cost Forecast | Projected costs | Facilitator fees + commission + operational costs + planned investments |

### Per Branch + Consolidated
All projection reports are available:
- Per individual branch
- Consolidated across all branches (Director view)

---

## Delegation System

Director and leaders can delegate/request work to teams:

### Types
- **Request Course** — Education Leader / Director requests Dept Leader to create a course (links to course creation flow in [curriculum.md](curriculum.md))
- **Request Project** — Director assigns a project to Operation Leader or any team
- **Delegate Task** — Any leader can delegate a task to their reports

### Delegation Entity (planned)

| Entity | Key Fields |
|--------|------------|
| DelegationEntity | id, type (request_course\|request_project\|delegate_task), title, description, requestedById, assignedToId, assignedToRole, dueDate?, priority (low\|medium\|high\|urgent), status (pending\|accepted\|in_progress\|completed\|cancelled), linkedEntityType?, linkedEntityId? |

### Integration
- Creates notification for assignee
- Tracks in approval/task queue
- Can be linked to a Course, Project, or other entity
- Status updates flow back to requester via notifications

---

## Routes (planned)

```
/business-development               → BusinessDevelopmentPage (overview)
/business-development/canvas        → BMCPage (Business Model Canvas)
/business-development/branches      → BranchManagementPage
/business-development/franchises    → FranchiseManagementPage
/business-development/okr           → OkrPage (OKR & KPI dashboard)
/business-development/investments   → InvestmentPlanPage
/business-development/projections   → ProjectionReportsPage
/business-development/delegations   → DelegationPage
```

---

## Role Access

| Feature | Director | Edu Leader | Op Leader | Acct Leader | Dept Leader |
|---------|----------|------------|-----------|-------------|-------------|
| BMC (full) | ✅ | View | View | View | View |
| Branch & Franchise | ✅ | View | View | View | — |
| OKR (company) | ✅ | View | View | View | — |
| OKR (department) | ✅ | ✅ (edu) | ✅ (ops) | ✅ (acct) | ✅ (own dept) |
| Investment Plan | ✅ (approve) | Propose | Propose | Propose | — |
| Financial Projections | ✅ (all) | View (edu) | View (ops) | ✅ (all) | View (dept) |
| Delegation | ✅ | ✅ | ✅ | ✅ | ✅ (own team) |

---

## Status

🔴 Not implemented — new domain for v2.
