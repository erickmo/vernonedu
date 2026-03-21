# Domain: Department

> Departments are organizational units under Education Leader, each led by a Department Leader.

---

## Overview

- Departments are created by Education Leader
- Department Leaders are **assigned by Education Leader, approved by Director** (approval workflow #1)
- Each department contains courses, batches, students, and talent pool members

---

## Routes

```
/departments                        → DepartmentPage (list)
/departments/:departmentId          → DepartmentDashboardPage (detail)
```

## Cubits

- `DepartmentCubit` — list
- `DepartmentSummaryCubit` — summary stats
- `DepartmentDashboardCubit` — detail page (parallel loads)

## Usecases

- `GetDepartmentsUseCase`
- `CreateDepartmentUseCase`
- `UpdateDepartmentUseCase`
- `DeleteDepartmentUseCase`
- `GetDepartmentSummaryUseCase(departmentId)`
- `GetDepartmentCoursesUseCase(departmentId)`
- `GetDepartmentBatchesUseCase(departmentId)`
- `GetDepartmentStudentsUseCase(departmentId)`
- `GetDepartmentTalentPoolUseCase(departmentId)`
- `AssignBatchFacilitatorUseCase(batchId, facilitatorId)`

## API Endpoints

```
GET    /departments              ?offset, limit
GET    /departments/:id
POST   /departments              body: {name, description?}
PUT    /departments/:id
DELETE /departments/:id
```

## Entities

| Entity | Key Fields |
|--------|------------|
| DepartmentEntity | id, name, description?, createdAt |
| DepartmentSummaryEntity | totalCourses, totalBatches, totalStudents, totalActiveBatches, totalTalentPool |
| DepartmentCourseEntity | id, name, totalTypes, totalVersions, isArchived |
| DepartmentBatchEntity | id, code, masterCourseName, status, facilitatorName?, totalEnrolled, startDate, endDate |
| DepartmentStudentEntity | id, name, email, studentCode, status, totalEnrollments |
| DepartmentTalentPoolEntity | id, participantId, participantName, status, companyName? |

## Dashboard Layout

Summary stat cards row + tabbed view: **Kursus | Batch | Siswa | Talent Pool**

---

## Status

✅ Functional — needs v2 update: Dept Leader assignment approval workflow.
