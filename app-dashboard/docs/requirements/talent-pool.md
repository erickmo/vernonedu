# Domain: Talent Pool

> Tracking graduates into career programs. Includes the Program Karir pipeline.

---

## Program Karir Pipeline

Program Karir courses have 2 phases:

```
Student enrolls in Program Karir batch
  → Phase 1: Learning (complete modules + sessions)
  → Phase 2: Internship (complete internship hours per InternshipConfig)
  → Student decides to join TalentPool?
     → Yes → Dept Leader provides recommendation
            → Student takes Character & Mindset test (per CharacterTestConfig)
            → Pass? → Registered in TalentPool program
            → Fail? → Not eligible (can retake based on policy)
```

---

## TalentPool Page (4 Tabs)

**Route:** `/talentpool` → `TalentPoolPage`
**Cubit:** `TalentPoolCubit` — `loadAll()` uses `Future.wait` for jobs + companies + all members, then splits members/placed client-side
**State:** `TalentPoolInitial | TalentPoolLoading | TalentPoolLoaded(jobs, companies, members, placed, isUpdatingStatus) | TalentPoolError`

### Tabs
1. **Lowongan Kerja** — grid cards, search + job type filter pills
2. **Perusahaan Rekanan** — grid cards, search
3. **Anggota Talent Pool** — DataTable, search + status filter pills, update status action
4. **Sudah Diterima** — grid cards with gradient border, search

---

## Usecases

- `GetTalentPoolUseCase({limit, offset, status, masterCourseId, participantId})` — optional `participantId` for filtering by student
- `UpdateTalentPoolStatusUseCase(id, status, placement?)`
- `GetJobOpeningsUseCase()`
- `GetPartnerCompaniesUseCase()`

## API Endpoints

```
GET /talent-pool              ?offset, limit, status?, master_course_id?, participant_id?
GET /talent-pool/:id
PUT /talent-pool/:id/status   body: {status: "placed"|"inactive", placement?: {...}}
```

## Entities

| Entity | Key Fields |
|--------|------------|
| TalentPoolEntity | id, participantId, participantName, profession, targetCity, expectedSalary, cvUrl?, internalAssessment?, characterTestScore?, status (active\|placed\|inactive), isPlaced, placedAt?, companyName?, position? |
| JobOpeningEntity | id, title, companyId, companyName, location, salaryMin?, salaryMax?, jobType, description, requirements (List), postedAt, deadline?, isActive, requiredCourseName?, applicantCount |
| PartnerCompanyEntity | id, name, industry, location, website?, contactEmail?, contactPhone?, description, logoUrl?, partnerSince, isActive, totalHired, activeJobCount |

**Lint note:** Use `String fmt(int v) {...}` (function declaration), not `final fmt = (int v) {...}` (lambda), inside getters to satisfy `prefer_function_declarations_over_variables`.

---

## Status

✅ Functional — needs v2 updates: Program Karir pipeline flow (recommendation + test gating), InternshipConfig/CharacterTestConfig integration.
