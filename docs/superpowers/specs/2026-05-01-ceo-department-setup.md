# CEO Department Setup — Design Spec

**Date:** 2026-05-01  
**Scope:** Add protected `/admin/` routes to React frontend for CEO to manage departments and assign department leaders.  
**Stack:** React 18 + TypeScript, React Router v6, React Query, React Hook Form, Zod validation, Tailwind + Radix UI, Axios  
**API Base:** `http://localhost:8081/api/v1`

---

## Overview

CEO (Director role) needs a web interface to:
1. Create departments (with required leader assignment at creation)
2. View department list with leaders
3. View department details
4. Change department leader after creation
5. Edit department info (name, description, status)
6. Delete departments

Leader assignment follows approval workflow:
- **Director (CEO):** Self-approves (no queue)
- **Non-Director staff:** Requires Education Leader approval, then Director approval

---

## Routes & Navigation

### Protected Routes

All routes under `/admin` require:
- User authenticated (valid JWT in localStorage)
- User role = `director`
- Redirect to `/login` if not authenticated
- Show 403 page if insufficient role

```
/admin
  /departments              [GET] → List page
  /departments/new          [GET] → Create page
  /departments/:id          [GET] → Detail page (view + edit + assign leader)
```

### Navigation Structure

**Top navbar:**
- Logo + brand name
- Breadcrumb (Admin > Departments > [current section])
- User menu: [Director Name] > Logout

**Sidebar:**
- Dashboard (placeholder for future)
- Departments (current)
- Users (placeholder for future)
- Settings (placeholder for future)

---

## Data Model

### Department Entity

```typescript
interface Department {
  id: string;
  name: string;
  description: string;
  leaderId: string;           // Required
  leaderName?: string;        // Denormalized, populated from staff list
  leaderRole?: string;        // Populated from staff list
  leaderAvatar?: string;      // Populated from staff list
  isActive: boolean;
  courseCount?: number;
  paidEnrollmentCount?: number;
  batchUpcoming?: number;
  batchOngoing?: number;
  batchCompleted?: number;
  createdAt?: string;
  updatedAt?: string;
}
```

### Staff/User Entity (for leader selection)

```typescript
interface Staff {
  id: string;
  name: string;
  email: string;
  role: string;              // director, education_leader, dept_leader, course_owner, facilitator, etc.
  avatar?: string;
}
```

---

## Page Design

### 1. Department List Page (`/admin/departments`)

**Layout:**
- Header: "Departemen" title + description
- Search bar: filter by department name (client-side or server-side)
- Button: "Tambah Departemen" (New Department)
- Table/Grid: department list

**Table Columns:**
| Column | Content | Actions |
|--------|---------|---------|
| Name | Dept name + avatar | - |
| Leader | Leader name + avatar (clickable → detail) | - |
| Active | Status badge (Active/Inactive) | - |
| Courses | Count of courses | - |
| Actions | Edit, Delete | Popup menu |

**Interactions:**
- Row click → detail page
- "Edit" → detail page
- "Delete" → confirmation dialog → delete mutation
- "Tambah Departemen" → create page

**States:**
- **Loading:** Skeleton loaders for table rows
- **Empty:** "Belum ada departemen. Buat yang pertama?" + button
- **Error:** Toast notification + retry button
- **Success:** Toast "Departemen berhasil dihapus"

**Data Fetching:**
```typescript
useQuery(["departments"], getDepartments, {
  staleTime: 5 * 60 * 1000,  // 5 min cache
  enabled: user?.role === 'director'
})
```

---

### 2. Create Department Page (`/admin/departments/new`)

**Form Layout:**
- Heading: "Buat Departemen Baru"
- Form fields below

**Form Fields:**

1. **Name** (required)
   - Type: Text input
   - Label: "Nama Departemen *"
   - Validation: 1-100 characters
   - Error message: "Nama harus 1-100 karakter"

2. **Description** (optional)
   - Type: Textarea
   - Label: "Deskripsi"
   - Validation: max 500 characters
   - Error message: "Deskripsi maksimal 500 karakter"

3. **Leader** (required)
   - Type: Searchable dropdown (Radix UI Select + search)
   - Label: "Kepala Departemen *"
   - Options: Staff list (fetched on page load)
   - Display format: `[Avatar] Name - Role`
   - Validation: required, valid staff ID
   - Error message: "Pilih kepala departemen"
   - Search: filters by name (client-side)

**Form Actions:**
- Cancel button → back to list
- Save button → validate + submit + redirect to detail page

**Submission:**
```typescript
POST /api/v1/departments
{
  "name": string,
  "description": string,
  "leader_id": string,
  "is_active": true
}
```

**Validation:**
- Use React Hook Form + Zod schema
- Show inline field errors below each field
- Disable submit button if form invalid or submitting

**States:**
- **Loading:** Disabled submit button, spinner
- **Success:** Redirect to `/admin/departments/:id`
- **Error:** Toast notification + keep form data

---

### 3. Department Detail Page (`/admin/departments/:id`)

**Layout:**
```
[Back button] Department Name
┌─────────────────────────────┐
│ Section 1: Department Info  │
├─────────────────────────────┤
│ Section 2: Current Leader   │
├─────────────────────────────┤
│ Section 3: Statistics       │
├─────────────────────────────┤
│ Section 4: Actions          │
└─────────────────────────────┘
```

#### Section 1: Department Info (Editable)

Card layout:
- Name field (editable inline or modal)
- Description field (editable)
- Status toggle (Active/Inactive)
- Edit button → opens form modal

Form modal:
- Same fields as create page (name, description)
- Submit: PATCH `/api/v1/departments/:id`
- Cancel: close modal

#### Section 2: Current Leader (Assignable)

Card layout:
```
┌─────────────────────────────┐
│ Kepala Departemen Saat Ini  │
├─────────────────────────────┤
│ [Avatar] Name               │
│          Role               │
│                             │
│ [Ubah Kepala Departemen]    │
└─────────────────────────────┘
```

"Ubah Kepala Departemen" button → modal with:
- Dropdown: Select new leader (same as create form)
- Current leader pre-selected
- Submit: PATCH `/api/v1/departments/:id`
  ```json
  { "leader_id": string }
  ```

**Approval Logic (Client-side):**
- If user.role = director: Submit directly (auto-approved)
- Else: Submit + show "Pending approval dari Education Leader"

#### Section 3: Statistics

Grid of stat boxes:
- Courses: count of courses in dept
- Students (Paid): paid enrollment count
- Batches:
  - Upcoming (badge)
  - Ongoing (badge)
  - Completed (badge)

#### Section 4: Actions

Button row:
- Delete Department (red button)
  - Confirmation dialog: "Yakin ingin menghapus departemen 'X'?"
  - Delete: DELETE `/api/v1/departments/:id`
  - On success: redirect to `/admin/departments`

**States:**
- **Loading:** Skeleton loader for sections
- **Error:** Toast notification on section load failure
- **Updating:** Disabled buttons, loading spinner in button
- **Success:** Toast notification "Departemen berhasil diupdate"

**Data Fetching:**
```typescript
useQuery(["department", id], () => getDepartment(id), {
  enabled: !!id
})
```

---

## API Integration

### Endpoints Used

**Get departments list:**
```
GET /api/v1/departments
Response: { data: Department[] }
```

**Get department detail:**
```
GET /api/v1/departments/:id
Response: { data: Department }
```

**Create department:**
```
POST /api/v1/departments
Body: { name, description, leader_id, is_active }
Response: { data: Department }
```

**Update department:**
```
PATCH /api/v1/departments/:id
Body: { name?, description?, is_active?, leader_id? }
Response: { data: Department }
```

**Delete department:**
```
DELETE /api/v1/departments/:id
Response: { success: true }
```

**Get staff list (for leader dropdown):**
```
GET /api/v1/staff?role=education_leader,director,course_owner
Response: { data: Staff[] }
```

### Error Handling

All API errors:
- Catch DioException
- Show toast: "Error: [message]" (red toast)
- Log to console
- Disable retry on 404 (not found)
- Enable retry on 5xx or network errors

---

## Component Architecture

```
AdminLayout
├── AdminNav
├── AdminSidebar
└── Outlet (route content)
    ├── DepartmentListPage
    │   ├── DepartmentSearch
    │   ├── DepartmentTable
    │   └── DepartmentDeleteDialog
    ├── DepartmentCreatePage
    │   └── DepartmentForm
    ├── DepartmentDetailPage
    │   ├── DepartmentInfoSection
    │   ├── DepartmentLeaderSection
    │   │   └── AssignLeaderDialog
    │   ├── DepartmentStatsSection
    │   └── DepartmentActionsSection
    └── [Other routes]
```

### Shared Components

- `DepartmentForm` — Form for create/edit (name, description, leader dropdown)
- `AssignLeaderDialog` — Modal for changing leader
- `StaffSelectDropdown` — Searchable staff dropdown for leader selection
- `DepartmentCard` — Card component for list view (optional if using table)
- `ConfirmDialog` — Reusable confirmation dialog for delete

---

## State Management

**React Query:**
- `useQuery(["departments"], getDepartments)` — list
- `useQuery(["department", id], getDepartment)` — detail
- `useMutation(createDepartment)` — create
- `useMutation(updateDepartment)` — update
- `useMutation(deleteDepartment)` — delete
- `useQuery(["staff"], getStaff)` — leader dropdown options

**Zustand (Auth):**
- Store user role + check for director permission in route guard

**React Hook Form:**
- Form state for department creation/editing
- Validation with Zod schema

---

## Error Handling & Validation

**Form Validation (Zod):**
```typescript
const departmentSchema = z.object({
  name: z.string().min(1, "Wajib diisi").max(100, "Max 100 karakter"),
  description: z.string().max(500, "Max 500 karakter").optional(),
  leaderId: z.string().min(1, "Pilih kepala departemen"),
});
```

**API Error Messages:**
- 400 Bad Request → Show field errors or "Periksa kembali data Anda"
- 404 Not Found → "Departemen tidak ditemukan"
- 409 Conflict → "Departemen sudah ada"
- 500 Server Error → "Terjadi kesalahan. Coba lagi nanti"
- Network error → "Koneksi bermasalah. Cek koneksi internet Anda"

**User Feedback:**
- Toast notifications (sonner): success (green), error (red), info (blue)
- Inline field errors from React Hook Form
- Loading states: disabled buttons + spinners
- Empty states: helpful message + CTA button

---

## Authorization & Security

**Route Protection:**
- All `/admin/*` routes check:
  - JWT token exists in localStorage
  - User role = `director`
  - Redirect unauthenticated → `/login`
  - Show 403 page for insufficient role

**API Calls:**
- Axios interceptor adds `Authorization: Bearer {token}` header
- API validates JWT on backend, returns 401 if invalid

**CSRF:**
- Use CORS + SameSite cookies (backend config)
- No additional CSRF token needed (API uses JWT)

---

## Loading & Empty States

**Loading:**
- Skeleton loaders on list table
- Skeleton card on detail page
- Loading spinner on buttons during mutation

**Empty:**
- List page: "Belum ada departemen. Buat yang pertama?" + button
- Table: "Tidak ada data" message

**Errors:**
- Toast notifications for all errors
- Retry button on critical failures
- Graceful fallback UI

---

## Performance Considerations

- **Caching:** React Query staleTime = 5 minutes
- **Pagination:** If dept count > 50, implement pagination on list
- **Search:** Client-side for now (server-side if > 100 depts)
- **Staff list:** Cache with 10 min staleTime (not frequently changing)

---

## Future Enhancements

- Batch operations (select multiple, bulk delete)
- Audit log (who changed what, when)
- Role-based approval queue (for non-directors)
- Department hierarchy (sub-departments)
- Export departments (CSV)

---

## File Structure

```
src/
├── pages/
│   └── admin/
│       ├── DepartmentListPage.tsx
│       ├── DepartmentCreatePage.tsx
│       ├── DepartmentDetailPage.tsx
│       └── AdminLayout.tsx
├── components/
│   └── admin/
│       ├── DepartmentForm.tsx
│       ├── DepartmentTable.tsx
│       ├── DepartmentCard.tsx
│       ├── StaffSelectDropdown.tsx
│       ├── AssignLeaderDialog.tsx
│       ├── ConfirmDialog.tsx
│       ├── AdminNav.tsx
│       └── AdminSidebar.tsx
├── lib/
│   ├── api.ts (axios instance)
│   ├── queries.ts (useQuery hooks)
│   └── mutations.ts (useMutation hooks)
├── schemas/
│   └── department.ts (Zod schemas)
└── types/
    └── department.ts (TypeScript interfaces)
```

---

## Success Criteria

- [ ] All routes protected (director-only access)
- [ ] Create department with required leader selection
- [ ] List shows departments + leaders
- [ ] Detail page shows all info + change leader
- [ ] Edit department name/description
- [ ] Delete department with confirmation
- [ ] Form validation (required fields, max length)
- [ ] API error handling + user-friendly messages
- [ ] Loading states on buttons + tables
- [ ] Toast notifications for success/error
- [ ] Responsive design (Tailwind)
- [ ] Accessibility (ARIA labels, keyboard nav)
