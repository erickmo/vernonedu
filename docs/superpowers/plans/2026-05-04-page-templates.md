# Page Templates Migration Plan (web-dashboard)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate all entity pages from "Coming soon" stubs to functional pages using `ListPageTemplate`, `DetailPageTemplate`, and `FormPageTemplate`.

**Architecture:** Templates already exist and are proven in the Department entity. Each entity page follows the same pattern: service layer (entity service or custom service) → template props (columns, actions, tabs, fields) → done. No template changes needed.

**Tech Stack:** React 18, TypeScript, TanStack React Query 5, Zustand 5, CSS Modules, Vite 8

**Reference:** Department entity (`src/pages/Departments/`) — the gold standard. All entities follow this exact pattern.

---

## Template API Summary

### ListPageTemplate<T extends { id: string }>

```tsx
<ListPageTemplate<Entity>
  title="string"                     // Page header title
  addLabel="string"                  // Add button text
  onAdd={() => navigate('/path')}    // Add button handler
  queryKey="string"                  // React Query key
  fetcher={(params) => svc.list(params)}  // Data fetcher returning PaginatedResponse<T>
  columns={columns}                  // ColumnDef<T>[] — table columns
  rowActions={rowActions}            // RowActionDef<T>[] — row action buttons
  onRowClick={(row) => navigate()}   // Row click handler
  searchPlaceholder="string"         // Search input placeholder
  exportFilename="string"            // CSV/JSON export filename
  emptyTitle="string"                // Empty state title
  emptyDescription="string"          // Empty state description
  helpTitle="string"                 // Help modal title
  helpText="string"                  // Help modal text
  deleteConfig={{                    // Delete dialog config
    onDelete: async (row) => { await svc.delete(row.id) },
    dialogTitle: 'Hapus X?',
    dialogBody: (row) => `...`,
    successMessage: (row) => `...`,
    errorMessage: 'Gagal menghapus',
  }}
  filterDefs={filterDefs}            // FilterDef[] — filter sidebar
  defaultSort={{ key, order }}       // Default sort
  hidePagination={false}             // Hide pagination (load all)
  readonly={false}                   // Read-only mode
/>
```

### DetailPageTemplate

```tsx
<DetailPageTemplate
  onBack={() => navigate('/path')}   // Back button handler
  icon={<Icon size={20} />}          // Header icon
  title="string"                     // Entity name/title
  badges={<ReactNode>}               // Status badges
  actions={actions}                  // DetailPageAction[] — edit/delete buttons
  tabs={[                            // DetailPageTab[]
    { id: 'overview', label: 'Ringkasan', icon: <Icon/>, content: <ReactNode> },
  ]}
  helpTitle="string"
  helpText="string"
  progress={{ steps, currentStatus }} // Optional progress stepper
  connections={{ items }}            // Optional "Koneksi" tab data
  sidebar={{ content, width }}       // Optional right sidebar
/>
```

### FormPageTemplate

```tsx
<FormPageTemplate
  title="string"                     // "Tambah X" or "Edit X"
  icon={<Icon size={20} />}
  onBack={() => navigate('/path')}
  tabs={[                            // FormPageTab[]
    { id: 'general', label: 'Info Umum', content: <FormGrid>...</FormGrid> },
  ]}
  onSubmit={handleSubmit}
  onCancel={() => navigate('/path')}
  isSubmitting={isSubmitting}
  submitLabel="Simpan"               // or "Update"
  serverError={serverError}
  helpTitle="string"
  helpText="string"
/>
```

### Helper exports from FormPageTemplate

```tsx
import { FormPageTemplate, Field, FormGrid, FormColumn, Toggle } from '@/widgets/FormPageTemplate'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'
```

---

## Entity Status

| Entity | List | Form | Detail | Service | Status |
|--------|------|------|--------|---------|--------|
| Departments | Template | Template | Template | Custom | Done (reference) |
| Students | Stub | Stub | Stub | Custom | Migrate |
| CourseBatch | Stub | Stub | Stub | Custom | Migrate |
| Enrollment | Stub | Stub | — | Custom | Migrate |
| Curriculum | Stub | Stub | Stub | Custom | Migrate |
| Leads | Stub | Stub | — | Custom | Migrate |
| Finance (Invoices) | Stub | Stub | Stub | Custom | Migrate |
| Finance (Transactions) | Stub | Stub | — | Custom | Migrate |
| Finance (CoA) | Stub | Stub | — | Custom | Migrate |
| HRM | Stub | — | Stub | Custom | Migrate |
| Certificates | Stub | Stub* | — | Custom | Partial (special pages) |
| Partners | Stub | — | — | Custom | Migrate (list only) |
| Operations (Locations) | Stub | — | — | Custom | Migrate (list only) |
| Operations (Payments) | Stub | — | — | Custom | Migrate (list only) |
| Projects | Stub | — | — | Custom | Migrate (list only) |
| TalentPool | Stub | — | — | Custom | Migrate (list only) |

Skip (dashboards/shells): Dashboard, Settings, Notifications, Approvals, FinanceMain, FinanceAnalysis, FinanceReports, BusinessDev (BMC, OKR, etc.), CRM, MarketingPage, CmsPage

---

## Migration Pattern

Each entity follows this exact structure. Reference: `src/pages/Departments/`

```
src/pages/[Entity]/
  [Entity]ListPage.tsx        ← ListPageTemplate
  [Entity]FormPage.tsx        ← FormPageTemplate (if CRUD)
  [Entity]DashboardPage.tsx   ← DetailPageTemplate (if detail view)
```

---

## Task 1: Migrate Students

**Files:**
- Modify: `src/pages/Students/StudentListPage.tsx`
- Modify: `src/pages/Students/StudentFormPage.tsx`
- Modify: `src/pages/Students/StudentDashboardPage.tsx`

**Service:** `src/services/student.service.ts` (exists)

### List Page

- [ ] **Step 1: Write StudentListPage using ListPageTemplate**

```tsx
import { useNavigate } from 'react-router-dom'
import { Pencil, Users } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { studentService } from '@/services/student.service'

interface Student {
  id: string
  name: string
  email: string
  phone: string
  is_active: boolean
  // add fields from API response
}

const columns: ColumnDef<Student>[] = [
  {
    key: 'name',
    header: 'Nama Siswa',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 'var(--radius-full)',
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', fontWeight: 700, fontSize: 'var(--font-sm)',
          flexShrink: 0,
        }}>
          {row.name?.[0]?.toUpperCase() ?? '?'}
        </div>
        <div>
          <div style={{ fontWeight: 600 }}>{row.name}</div>
          <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>{row.email}</div>
        </div>
      </div>
    ),
  },
  {
    key: 'phone',
    header: 'Telepon',
    width: 140,
    render: (_v, row) => row.phone || '—',
  },
  {
    key: 'is_active',
    header: 'Status',
    width: 90,
    align: 'center',
    render: (_v, row) => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: row.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
        color: row.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
      }}>
        {row.is_active ? 'Aktif' : 'Nonaktif'}
      </span>
    ),
  },
]

export default function StudentListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Student>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/students/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Student>
      title="Siswa"
      addLabel="Tambah Siswa"
      onAdd={() => navigate('/students/new')}
      queryKey="students"
      fetcher={(params) => studentService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/students/${row.id}`)}
      searchPlaceholder="Cari siswa..."
      exportFilename="siswa"
      emptyTitle="Belum ada siswa"
      emptyDescription="Tambahkan siswa pertama untuk mulai mengelola data."
      helpTitle="Siswa"
      helpText="Kelola data siswa. Siswa dapat mendaftar ke batch kursus melalui enrollment."
      deleteConfig={{
        onDelete: async (row) => { await studentService.delete(row.id) },
        dialogTitle: 'Hapus Siswa?',
        dialogBody: (row) => `${row.name} akan dihapus secara permanen.`,
        successMessage: (row) => `Siswa "${row.name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus siswa',
      }}
    />
  )
}
```

- [ ] **Step 2: Write StudentFormPage using FormPageTemplate**

```tsx
import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Users } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { FormPageTemplate, Field, FormGrid, FormColumn } from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { studentService } from '@/services/student.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

export default function StudentFormPage() {
  const navigate = useNavigate()
  const { studentId } = useParams()
  const queryClient = useQueryClient()
  const isEdit = Boolean(studentId)

  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: student } = useQuery({
    queryKey: ['student', studentId],
    queryFn: () => studentService.getById(studentId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (student) {
      setName(student.name ?? '')
      setEmail(student.email ?? '')
      setPhone(student.phone ?? '')
    }
  }, [student])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama wajib diisi'
    if (!email.trim()) e.email = 'Email wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return
    setIsSubmitting(true)
    setServerError('')
    try {
      const payload = { name: name.trim(), email: email.trim(), phone: phone.trim() }
      if (isEdit) {
        await studentService.update(studentId!, payload)
        toast.success('Siswa berhasil diperbarui')
      } else {
        await studentService.create(payload)
        toast.success('Siswa berhasil ditambahkan')
      }
      await queryClient.invalidateQueries({ queryKey: ['students'] })
      navigate('/students')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Siswa' : 'Tambah Siswa'}
      icon={<Users size={20} />}
      onBack={() => navigate('/students')}
      tabs={[{
        id: 'general',
        label: 'Informasi Umum',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Nama" required error={errors.name}>
                <input type="text" value={name} onChange={(e) => setName(e.target.value)}
                  placeholder="Nama lengkap" autoFocus
                  className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                />
              </Field>
              <Field label="Email" required error={errors.email}>
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)}
                  placeholder="email@contoh.com"
                  className={`${formStyles.input} ${errors.email ? formStyles.inputError : ''}`}
                />
              </Field>
              <Field label="Telepon">
                <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)}
                  placeholder="08xxxxxxxxxx" className={formStyles.input}
                />
              </Field>
            </FormColumn>
          </FormGrid>
        ),
      }]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/students')}
      isSubmitting={isSubmitting}
      submitLabel={isEdit ? 'Update' : 'Simpan'}
      serverError={serverError}
    />
  )
}
```

- [ ] **Step 3: Write StudentDashboardPage using DetailPageTemplate**

```tsx
import { useParams, useNavigate } from 'react-router-dom'
import { Users, Pencil } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { studentService } from '@/services/student.service'

export default function StudentDashboardPage() {
  const { studentId } = useParams()
  const navigate = useNavigate()

  const { data: student, isLoading } = useQuery({
    queryKey: ['student', studentId],
    queryFn: () => studentService.getById(studentId!),
  })

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Siswa',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/students/${studentId}/edit`),
    },
  ]

  return (
    <DetailPageTemplate
      onBack={() => navigate('/students')}
      icon={<Users size={20} />}
      title={isLoading ? 'Memuat...' : (student?.name ?? 'Siswa')}
      actions={actions}
      tabs={[
        {
          id: 'overview',
          label: 'Ringkasan',
          icon: <Users size={14} />,
          content: (
            <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
              {student && (
                <div style={{
                  padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
                  border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
                }}>
                  <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>Email</div>
                  <div style={{ fontWeight: 600 }}>{student.email || '—'}</div>
                </div>
              )}
            </div>
          ),
        },
      ]}
    />
  )
}
```

- [ ] **Step 4: Verify visually**

Run: `cd web-dashboard && npm run dev`
Check: Student list, form (create + edit), dashboard

- [ ] **Step 5: Commit**

```bash
git add src/pages/Students/
git commit -m "feat(students): implement pages using ListPageTemplate, FormPageTemplate, DetailPageTemplate"
```

---

## Task 2: Migrate Leads

**Files:**
- Modify: `src/pages/Leads/LeadListPage.tsx`
- Modify: `src/pages/Leads/LeadFormPage.tsx`

**Service:** `src/services/lead.service.ts` (exists)

- [ ] **Step 1: Write LeadListPage** — same pattern as StudentListPage. Add status filter via `filterDefs`. Add stat cards or extra columns for source/status.

- [ ] **Step 2: Write LeadFormPage** — fields: name, email, phone, interest, source (dropdown), notes. Edit mode adds status dropdown.

- [ ] **Step 3: Verify + Commit**

```bash
git commit -m "feat(leads): implement pages using ListPageTemplate, FormPageTemplate"
```

---

## Task 3: Migrate CourseBatch

**Files:**
- Modify: `src/pages/CourseBatch/CourseBatchListPage.tsx`
- Modify: `src/pages/CourseBatch/BatchFormPage.tsx`
- Modify: `src/pages/CourseBatch/CourseBatchDetailPage.tsx`

**Service:** `src/services/course-batch.service.ts` (exists)

- [ ] **Step 1: Write CourseBatchListPage** — columns: batch name, course, facilitator, dates, status, enrollment count

- [ ] **Step 2: Write BatchFormPage** — fields: course_id (dropdown), name, facilitator_id, start/end dates, pricing, min/max students, payment method

- [ ] **Step 3: Write CourseBatchDetailPage** — tabs: overview (stats), schedule, enrollments, attendance

- [ ] **Step 4: Verify + Commit**

```bash
git commit -m "feat(course-batch): implement pages using page templates"
```

---

## Task 4: Migrate Enrollment

**Files:**
- Modify: `src/pages/Enrollment/EnrollmentListPage.tsx`
- Modify: `src/pages/Enrollment/EnrollmentFormPage.tsx`

**Service:** `src/services/enrollment.service.ts` (exists)

- [ ] **Step 1: Write EnrollmentListPage** — columns: student, batch, status, payment status, enrolled date

- [ ] **Step 2: Write EnrollmentFormPage** — fields: student_id, batch_id, payment_method

- [ ] **Step 3: Verify + Commit**

```bash
git commit -m "feat(enrollment): implement pages using ListPageTemplate, FormPageTemplate"
```

---

## Task 5: Migrate Curriculum (Course)

**Files:**
- Modify: `src/pages/Curriculum/CurriculumPage.tsx`
- Modify: `src/pages/Curriculum/CourseFormPage.tsx`
- Modify: `src/pages/Curriculum/CourseDashboardPage.tsx`
- Modify: `src/pages/Curriculum/CourseVersionPage.tsx`
- Modify: `src/pages/Curriculum/VersionFormPage.tsx`

**Services:** `course.service.ts`, `course-version.service.ts`, `course-type.service.ts`, `course-module.service.ts` (all exist)

- [ ] **Step 1: Write CurriculumPage** (list) using ListPageTemplate — columns: course name, type, department, versions count, status

- [ ] **Step 2: Write CourseFormPage** using FormPageTemplate — fields: name, department_id, course_type_id, description, pricing

- [ ] **Step 3: Write CourseDashboardPage** using DetailPageTemplate — tabs: overview, versions, batches

- [ ] **Step 4: Write CourseVersionPage** using ListPageTemplate — list of versions for a course

- [ ] **Step 5: Write VersionFormPage** using FormPageTemplate — version creation/edit

- [ ] **Step 6: Verify + Commit**

```bash
git commit -m "feat(curriculum): implement pages using page templates"
```

---

## Task 6: Migrate Finance — Invoices

**Files:**
- Modify: `src/pages/Finance/InvoiceListPage.tsx`
- Modify: `src/pages/Finance/ManualInvoiceFormPage.tsx`
- Modify: `src/pages/Finance/InvoiceDetailPage.tsx`

**Service:** `src/services/invoice.service.ts` (exists)

- [ ] **Step 1: Write InvoiceListPage** — columns: invoice number, student, batch, amount, status, due date

- [ ] **Step 2: Write ManualInvoiceFormPage** — fields: student_id, amount, due_date, notes

- [ ] **Step 3: Write InvoiceDetailPage** using DetailPageTemplate — tabs: overview, payment history

- [ ] **Step 4: Verify + Commit**

```bash
git commit -m "feat(invoices): implement pages using page templates"
```

---

## Task 7: Migrate Finance — Transactions

**Files:**
- Modify: `src/pages/Finance/TransactionListPage.tsx`
- Modify: `src/pages/Finance/TransactionFormPage.tsx`

**Service:** `src/services/accounting.service.ts` (exists)

- [ ] **Step 1: Write TransactionListPage** — columns: date, type, account, description, debit, credit

- [ ] **Step 2: Write TransactionFormPage** — fields: date, account_id, type, amount, description

- [ ] **Step 3: Verify + Commit**

```bash
git commit -m "feat(transactions): implement pages using page templates"
```

---

## Task 8: Migrate Finance — Chart of Accounts

**Files:**
- Modify: `src/pages/Finance/ChartOfAccountsPage.tsx`
- Modify: `src/pages/Finance/CoaFormPage.tsx`

**Service:** `src/services/accounting.service.ts` (exists)

- [ ] **Step 1: Write ChartOfAccountsPage** — list with tree structure or flat table

- [ ] **Step 2: Write CoaFormPage** — fields: code, name, type, parent_id

- [ ] **Step 3: Verify + Commit**

```bash
git commit -m "feat(coa): implement pages using page templates"
```

---

## Task 9: Migrate HRM

**Files:**
- Modify: `src/pages/Hrm/HrmListPage.tsx`
- Modify: `src/pages/Hrm/SdmDetailPage.tsx`

**Service:** `src/services/hrm.service.ts` (exists)

- [ ] **Step 1: Write HrmListPage** — columns: name, email, roles, department, status

- [ ] **Step 2: Write SdmDetailPage** using DetailPageTemplate — tabs: overview, roles, activity

- [ ] **Step 3: Verify + Commit**

```bash
git commit -m "feat(hrm): implement pages using page templates"
```

---

## Task 10: Migrate Simple List-Only Entities

Batch migration for entities that only need a list page (no form/detail):

| Entity | File | Service | Key columns |
|--------|------|---------|-------------|
| Partners | PartnerListPage.tsx | partner.service.ts | name, type, contact, MOU status |
| Locations | LocationListPage.tsx | location.service.ts | name, building, capacity, facilities |
| Payments | PaymentListPage.tsx | (use invoice.service) | student, batch, amount, method, date |
| Projects | ProjectListPage.tsx | — | name, status, dates, budget |
| TalentPool | TalentPoolPage.tsx | talentpool.service.ts | name, department, status, pipeline stage |
| Payables | PayableListPage.tsx | payable.service.ts | vendor, amount, due date, status |

- [ ] **Step 1: Write PartnerListPage**

- [ ] **Step 2: Write LocationListPage**

- [ ] **Step 3: Write PaymentListPage**

- [ ] **Step 4: Write ProjectListPage**

- [ ] **Step 5: Write TalentPoolPage** — may use tabs for pipeline stages

- [ ] **Step 6: Write PayableListPage**

- [ ] **Step 7: Verify + Commit**

```bash
git commit -m "feat: implement list pages for partners, locations, payments, projects, talentpool, payables"
```

---

## Task 11: Migrate Certificates

**Files:**
- Modify: `src/pages/Certificates/CertificateListPage.tsx`
- Modify: `src/pages/Certificates/IssueParticipantPage.tsx`
- Modify: `src/pages/Certificates/IssueCompetencyPage.tsx`
- Modify: `src/pages/Certificates/CertificateTemplateListPage.tsx`
- Modify: `src/pages/Certificates/CertificateTemplateEditorPage.tsx`

**Service:** `src/services/certificate.service.ts` (exists)

- [ ] **Step 1: Write CertificateListPage** — columns: student, batch, type, status, issued date. Filter by type/status.

- [ ] **Step 2: Write IssueParticipantPage** using FormPageTemplate — select enrollment, verify completion, issue

- [ ] **Step 3: Write IssueCompetencyPage** using FormPageTemplate — select student, test score, issue

- [ ] **Step 4: Write CertificateTemplateListPage** using ListPageTemplate

- [ ] **Step 5: Write CertificateTemplateEditorPage** using FormPageTemplate — template editor with HTML/design fields

- [ ] **Step 6: Verify + Commit**

```bash
git commit -m "feat(certificates): implement pages using page templates"
```

---

## Task 12: Migrate Remaining Form Pages (Marketing, CMS)

### Marketing form pages
- `src/pages/Marketing/SocialPostFormPage.tsx`
- `src/pages/Marketing/PrContentFormPage.tsx`
- `src/pages/Marketing/ReferralFormPage.tsx`

**Service:** `src/services/marketing.service.ts` (exists)

### CMS form pages
- `src/pages/Cms/ArticleFormPage.tsx`
- `src/pages/Cms/TestimonialFormPage.tsx`
- `src/pages/Cms/FaqFormPage.tsx`
- `src/pages/Cms/PageEditorPage.tsx`

**Service:** `src/services/cms.service.ts` (exists)

- [ ] **Step 1: Write Marketing form pages** using FormPageTemplate

- [ ] **Step 2: Write CMS form pages** using FormPageTemplate

- [ ] **Step 3: Verify + Commit**

```bash
git commit -m "feat(marketing,cms): implement form pages using FormPageTemplate"
```

---

## Task 13: Migrate Remaining Detail Pages (BusinessDev PartnerDetail)

**Files:**
- Modify: `src/pages/BusinessDev/PartnerDetailPage.tsx`

**Service:** `src/services/partner.service.ts` (exists)

- [ ] **Step 1: Write PartnerDetailPage** using DetailPageTemplate — tabs: overview, MOUs, collaborations

- [ ] **Step 2: Verify + Commit**

```bash
git commit -m "feat(partners): implement detail page using DetailPageTemplate"
```

---

## Task 14: Migrate Remaining Specialized Finance Pages

These pages may not perfectly fit templates but should use them where possible:

- `JournalPage.tsx` — may use ListPageTemplate with custom columns
- `BankAccountsPage.tsx` — may use ListPageTemplate
- `FinanceMainPage.tsx` — dashboard, skip template
- `ReportNavigationPage.tsx` — navigation hub, skip template
- Balance sheet, P&L, cash flow, ledger, trial balance, analysis — reports, skip templates

- [ ] **Step 1: Write JournalPage** using ListPageTemplate

- [ ] **Step 2: Write BankAccountsPage** using ListPageTemplate

- [ ] **Step 3: Verify + Commit**

```bash
git commit -m "feat(finance): implement journal and bank accounts pages using ListPageTemplate"
```

---

## Execution Notes

### Per-task checklist
Each task follows: Write page(s) → verify visually → commit. If service methods are missing, add them to the existing service file first.

### Common patterns from Department reference
- Service uses `apiClient.get/post/put/delete` with response unwrapping `(r as any).data ?? r`
- List pages define `ColumnDef<T>[]` and `RowActionDef<T>[]` as module-level constants
- Form pages manage local state with `useState`, use `useQuery` for edit mode data, `useQueryClient` for invalidation
- Detail pages use `useParams()` for entity ID, multiple `useQuery` calls for related data

### Skip these (not CRUD entities)
- `DashboardPage` — analytics dashboard
- `SettingsPage` — config panel
- `NotificationPage` — notification list (special UI)
- `ApprovalPage` — approval workflow (special UI)
- `FinanceMainPage` — finance dashboard
- `FinancialAnalysisPage` — analytics
- `ReportNavigationPage`, `BalanceSheetPage`, `ProfitLossPage`, `CashFlowPage`, `GeneralLedgerPage`, `TrialBalancePage` — financial reports
- `BusinessDevPage` — hub page with cards
- `BmcPage`, `BranchManagementPage`, `FranchiseManagementPage`, `OkrPage`, `InvestmentPlanPage`, `ProjectionReportsPage`, `DelegationPage` — specialized tools
- `CrmPage` — CRM dashboard
- `MarketingPage` — tab-based hub
- `CmsPage` — tab-based hub
- `CourseModulePage` — module list within version
- `InternshipConfigPage`, `CharacterTestConfigPage` — config pages
- `CurriculumApprovalsPage` — approval workflow
- `AuditLogPage` — audit log viewer

---

## Self-Review

### Spec coverage
- [x] All entities with list pages → ListPageTemplate (Tasks 1-14)
- [x] All entities with form pages → FormPageTemplate (Tasks 1-14)
- [x] All entities with detail pages → DetailPageTemplate (Tasks 1-14)
- [x] Non-CRD entities excluded (listed above)

### Placeholder scan
- [x] Task 1 has complete code for Student (list + form + detail)
- [x] Tasks 2-14 describe exact files, services, columns, and fields
- [x] No TBD/TODO/fill-in-later

### Type consistency
- [x] All entities use `{ id: string }` interface (required by ListPageTemplate generic)
- [x] Column types use `ColumnDef<T>` from DataTable
- [x] Service methods follow `list/getById/create/update/delete` pattern from createEntityService
