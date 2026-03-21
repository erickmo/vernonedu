# Domain: Curriculum

> MasterCourse → CourseType → CourseVersion → CourseModule
> Includes course proposals, versioning approvals, and supporting app linking.

---

## Hierarchy

```
Department
  └──< MasterCourse (template kurikulum)
         └──< CourseType
         │      ├── pricing: normal_price + min_price (for promo)
         │      ├── min/max participants
         │      ├── modules (via CourseVersion)
         │      ├── number of sessions
         │      └──< CourseVersion (versioning, approved by Dept Leader)
         │             └──< CourseModule (unit pembelajaran)
         ├── InternshipConfig (for Program Karir type)
         ├── CharacterTestConfig (for Program Karir type)
         ├── CertificateTemplate (A4, per course)
         └── SupportingApp? (optional link to e.g. app-entrepreneur)
```

---

## Course Types (Fixed Categories)

| Type | Description | Special Behavior |
|------|-------------|------------------|
| Program Karir | 2 parts: learning + internship → talent pool | Has InternshipConfig, CharacterTestConfig |
| Reguler | Standard course | — |
| Privat | Private/1-on-1 course | — |
| Kolaborasi dengan Sekolah | School collaboration | — |
| Kolaborasi dengan Universitas | University collaboration | — |
| Inhouse Training | Corporate in-house | Payment method: batch lump sum |

Each type has its own: **pricing (normal + min), modules, session count, min/max participants**.

---

## Course Creation Flow

### Bottom-up (Dept Leader / Course Creator proposes)
1. Dept Leader or Course Creator creates course proposal
2. Education Leader reviews and approves
3. Once approved → course available to sell (batch can be created)

### Top-down (Education Leader / Director requests)
1. Education Leader or Director requests a specific course to Dept Leader
2. Dept Leader creates the course through the same proposal flow
3. Education Leader approves

---

## Course Versioning

Course Owner can propose changes to modules and session count:
1. Course Owner creates new CourseVersion with updated modules/sessions
2. Dept Leader reviews and approves
3. New version is launched (previous versions kept for history)

---

## Supporting Apps

Some courses link to a supporting app/portal:
- Configured per course (optional field: `supporting_app_url`)
- Students get access to the app when enrolled, revoked when batch completes / student withdraws / payment fails

| Course | Supporting App |
|--------|---------------|
| Entrepreneurship | `app-entrepreneur` (port 3000) |
| Block Coding | `app-blockcoding` (port 3002) |

---

## Ads Template

- Each course has a default ads template (managed by Marketing Team)
- When course or course batch is updated, the system auto-edits the ads template to reflect the latest information

---

## Routes

```
/curriculum                         → CoursePage (MasterCourse list)
/curriculum/types/:typeId           → CourseVersionPage
/curriculum/versions/:versionId     → CourseModulePage
/curriculum/:courseId               → CourseDashboardPage
/courses/:id                        → CourseDashboardPage (backward compat)
```

## Cubits

- `CourseCubit` — MasterCourse list: `CourseInitial | CourseLoading | CourseLoaded(courses) | CourseError`
- `CourseTypeCubit` — types per master course
- `CourseVersionCubit` — versions per type
- `CourseModuleCubit` — modules per version

## Usecases

### MasterCourse
- `GetCoursesUseCase`, `CreateCourseUseCase`, `UpdateCourseUseCase`, `DeleteCourseUseCase`, `ArchiveCourseUseCase`

### CourseType
- `GetCourseTypesUseCase(masterCourseId)`, `CreateCourseTypeUseCase`, `UpdateCourseTypeUseCase`, `ToggleCourseTypeUseCase`

### CourseVersion
- `GetCourseVersionsUseCase(courseTypeId)`, `CreateCourseVersionUseCase`, `PromoteCourseVersionUseCase`

### CourseModule
- `GetCourseModulesUseCase(versionId)`, `CreateCourseModuleUseCase`, `UpdateCourseModuleUseCase`, `DeleteCourseModuleUseCase`

## API Endpoints

```
# MasterCourse
GET    /master-courses              ?offset, limit, status?, department_id?
GET    /master-courses/:id
POST   /master-courses              body: {name, description, department_id}
PUT    /master-courses/:id
POST   /master-courses/:id/archive
DELETE /master-courses/:id

# CourseType
GET    /course-types                ?master_course_id=:id
GET    /course-types/:id
POST   /course-types                body: {masterCourseId, name, description, normalPrice, minPrice, minParticipants, maxParticipants}
PUT    /course-types/:id
POST   /course-types/:id/toggle

# CourseVersion
GET    /course-versions             ?course_type_id=:id
GET    /course-versions/:id
POST   /course-versions             body: {courseTypeId, version, description?}
POST   /course-versions/:id/promote

# CourseModule
GET    /course-modules              ?course_version_id=:id
GET    /course-modules/:id
POST   /course-modules              body: {courseVersionId, title, orderIndex, contentUrl?, tools[], requirements[]}
PUT    /course-modules/:id
DELETE /course-modules/:id
```

## Entities

| Entity | Key Fields |
|--------|------------|
| CourseEntity | id, name, description, departmentId, departmentName?, isArchived, supportingAppUrl?, createdAt |
| CourseTypeEntity | id, masterCourseId, name, description, type (enum), normalPrice, minPrice, minParticipants, maxParticipants, isActive |
| CourseVersionEntity | id, courseTypeId, version, isActive, promotedAt?, totalModules |
| CourseModuleEntity | id, courseVersionId, title, orderIndex, contentUrl?, tools (List), requirements (List) |

### Module Tools & Requirements

Each CourseModule includes:
- **tools[]** — list of tools needed for this module (e.g. laptop, projector, soldering kit)
- **requirements[]** — list of requirements/prerequisites (e.g. software installed, materials to bring)

These are linked to class schedules and used by the operational team to:
- Prepare tools/materials before each session
- Match rooms with appropriate facilities (see [operations.md](operations.md))
- Display preparation checklist in the ops dashboard

---

## Design System Note

All VernonEdu apps must maintain **uniform design** that reflects VernonEdu brand identity — consistent fonts, colors, spacing, and component styles across `app-dashboard`, `app-student`, `app-entrepreneur`, `app-mentors`, `app-website`, and all other apps. See `AppColors`, `AppDimensions`, and `AppStrings` in each app's CLAUDE.md.

---

## Status

✅ Functional — needs v2 updates: pricing fields, participant limits, course type enum, supporting app config, module tools/requirements, ads template, approval workflows.
