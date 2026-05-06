# Delete Action — All Entity Detail Pages

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Hapus (Delete) action button to all 10 entity detail pages that currently lack it.

**Architecture:** Each delete action uses `window.confirm` for confirmation, calls the service `delete` method, shows toast feedback, then navigates back to the list page. Services missing a `delete` method get one added first. No validation logic — user will define that later.

**Tech Stack:** React 18, TypeScript, TanStack React Query, lucide-react (Trash2), existing service pattern (`apiClient.delete`)

---

## Files Modified

**Services (add delete method):**
- `web-dashboard/src/services/partner.service.ts` — add `delete`
- `web-dashboard/src/services/enrollment.service.ts` — add `delete`
- `web-dashboard/src/services/invoice.service.ts` — add `delete`
- `web-dashboard/src/services/payable.service.ts` — add `delete`
- `web-dashboard/src/services/hrm.service.ts` — add `deleteAttendance`, `deleteLeaveRequest`, `deletePayrollPeriod`

**Pages (add delete action):**
- `web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx`
- `web-dashboard/src/pages/CourseBatch/CourseBatchDetailPage.tsx`
- `web-dashboard/src/pages/Operations/LocationDetailPage.tsx`
- `web-dashboard/src/pages/Hrm/SdmDetailPage.tsx`
- `web-dashboard/src/pages/Enrollment/EnrollmentDetailPage.tsx`
- `web-dashboard/src/pages/Finance/InvoiceDetailPage.tsx`
- `web-dashboard/src/pages/Finance/PayableDetailPage.tsx`
- `web-dashboard/src/pages/Hrm/AttendanceDetailPage.tsx`
- `web-dashboard/src/pages/Hrm/LeaveDetailPage.tsx`
- `web-dashboard/src/pages/Hrm/PayrollDetailPage.tsx`

---

## Task 1: Add delete to partner.service.ts

**Files:**
- Modify: `web-dashboard/src/services/partner.service.ts`

- [ ] **Step 1: Add delete method before closing `}`**

In `partner.service.ts`, add before the closing `}` of the exported object:

```ts
  delete: (id: string) =>
    apiClient.delete<any>(`/partners/${id}`),
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/services/partner.service.ts
git commit -m "feat(partner): add delete method to partnerService"
```

---

## Task 2: Add delete to enrollment.service.ts

**Files:**
- Modify: `web-dashboard/src/services/enrollment.service.ts`

- [ ] **Step 1: Add delete method before closing `}`**

In `enrollment.service.ts`, add before the closing `}` of the exported object:

```ts
  delete: (id: string) =>
    apiClient.delete<any>(`/enrollments/${id}`),
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/services/enrollment.service.ts
git commit -m "feat(enrollment): add delete method to enrollmentService"
```

---

## Task 3: Add delete to invoice.service.ts

**Files:**
- Modify: `web-dashboard/src/services/invoice.service.ts`

- [ ] **Step 1: Add delete method before closing `}`**

In `invoice.service.ts`, add before the closing `}` of the exported object:

```ts
  delete: (id: string) =>
    apiClient.delete<any>(`/finance/invoices/${id}`),
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/services/invoice.service.ts
git commit -m "feat(invoice): add delete method to invoiceService"
```

---

## Task 4: Add delete to payable.service.ts

**Files:**
- Modify: `web-dashboard/src/services/payable.service.ts`

- [ ] **Step 1: Add delete method before closing `}`**

In `payable.service.ts`, add before the closing `}` of the exported object:

```ts
  delete: (id: string) =>
    apiClient.delete<any>(`/finance/payables/${id}`),
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/services/payable.service.ts
git commit -m "feat(payable): add delete method to payableService"
```

---

## Task 5: Add delete methods to hrm.service.ts

**Files:**
- Modify: `web-dashboard/src/services/hrm.service.ts`

- [ ] **Step 1: Add three delete methods before closing `}`**

In `hrm.service.ts`, add before the closing `}` of the exported `hrmService` object:

```ts
  deleteAttendance: (id: string) =>
    apiClient.delete<any>(`/hrm/attendance/${id}`),

  deleteLeaveRequest: (id: string) =>
    apiClient.delete<any>(`/hrm/leave-requests/${id}`),

  deletePayrollPeriod: (id: string) =>
    apiClient.delete<any>(`/hrm/payroll-periods/${id}`),
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/services/hrm.service.ts
git commit -m "feat(hrm): add deleteAttendance, deleteLeaveRequest, deletePayrollPeriod to hrmService"
```

---

## Task 6: Add delete action to PartnerDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the lucide import line (has `Handshake, Pencil, Plus, FileText, StickyNote, X`) and add `Trash2`:

```ts
import { Handshake, Pencil, Plus, FileText, StickyNote, X, Trash2 } from 'lucide-react'
```

- [ ] **Step 2: Add delete action to the `actions` array**

Find the `actions` array in `PartnerDetailPage`. Add this object at the end of the array (after the last existing action):

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus partner ini?')) return
        try {
          await partnerService.delete(partnerId!)
          toast.success('Partner berhasil dihapus')
          navigate('/business-dev/partners')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus partner')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx
git commit -m "feat(partner): add delete action to PartnerDetailPage"
```

---

## Task 7: Add delete action to CourseBatchDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/CourseBatch/CourseBatchDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Verify courseBatchService import exists**

Confirm `courseBatchService` is imported at the top. It should already be.

- [ ] **Step 3: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus batch ini?')) return
        try {
          await courseBatchService.delete(batchId!)
          toast.success('Batch berhasil dihapus')
          navigate('/course-batches')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus batch')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/pages/CourseBatch/CourseBatchDetailPage.tsx
git commit -m "feat(course-batch): add delete action to CourseBatchDetailPage"
```

---

## Task 8: Add delete action to LocationDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Operations/LocationDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus lokasi ini?')) return
        try {
          await locationService.deleteBuilding(buildingId!)
          toast.success('Lokasi berhasil dihapus')
          navigate('/pengembangan/locations')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus lokasi')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Operations/LocationDetailPage.tsx
git commit -m "feat(location): add delete action to LocationDetailPage"
```

---

## Task 9: Add delete action to SdmDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Hrm/SdmDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Verify userService import**

Confirm `userService` is imported. Check top of file — it may use `hrmService` instead for employee data. The delete endpoint is `DELETE /users/{id}` so use `userService.delete`. If `userService` is not imported, add:

```ts
import { userService } from '@/services/user.service'
```

- [ ] **Step 3: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus karyawan ini?')) return
        try {
          await userService.delete(employeeId!)
          toast.success('Karyawan berhasil dihapus')
          navigate('/hrm')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus karyawan')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/pages/Hrm/SdmDetailPage.tsx
git commit -m "feat(hrm): add delete action to SdmDetailPage"
```

---

## Task 10: Add delete action to EnrollmentDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Enrollment/EnrollmentDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus enrollment ini?')) return
        try {
          await enrollmentService.delete(enrollmentId!)
          toast.success('Enrollment berhasil dihapus')
          navigate('/enrollments')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus enrollment')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Enrollment/EnrollmentDetailPage.tsx
git commit -m "feat(enrollment): add delete action to EnrollmentDetailPage"
```

---

## Task 11: Add delete action to InvoiceDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Finance/InvoiceDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus invoice ini?')) return
        try {
          await invoiceService.delete(invoiceId!)
          toast.success('Invoice berhasil dihapus')
          navigate('/finance/invoices')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus invoice')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Finance/InvoiceDetailPage.tsx
git commit -m "feat(invoice): add delete action to InvoiceDetailPage"
```

---

## Task 12: Add delete action to PayableDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Finance/PayableDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus payable ini?')) return
        try {
          await payableService.delete(payableId!)
          toast.success('Payable berhasil dihapus')
          navigate('/finance/payables')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus payable')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Finance/PayableDetailPage.tsx
git commit -m "feat(payable): add delete action to PayableDetailPage"
```

---

## Task 13: Add delete action to AttendanceDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Hrm/AttendanceDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus absensi ini?')) return
        try {
          await hrmService.deleteAttendance(attendanceId!)
          toast.success('Absensi berhasil dihapus')
          navigate('/hrm/attendance')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus absensi')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Hrm/AttendanceDetailPage.tsx
git commit -m "feat(hrm): add delete action to AttendanceDetailPage"
```

---

## Task 14: Add delete action to LeaveDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Hrm/LeaveDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus permohonan cuti ini?')) return
        try {
          await hrmService.deleteLeaveRequest(leaveId!)
          toast.success('Permohonan cuti berhasil dihapus')
          navigate('/hrm/leaves')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus permohonan cuti')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Hrm/LeaveDetailPage.tsx
git commit -m "feat(hrm): add delete action to LeaveDetailPage"
```

---

## Task 15: Add delete action to PayrollDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Hrm/PayrollDetailPage.tsx`

- [ ] **Step 1: Add Trash2 to lucide import**

Find the existing lucide import and add `Trash2` to it.

- [ ] **Step 2: Add delete action to the `actions` array**

Find the `actions` array. Add at the end:

```ts
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus periode payroll ini?')) return
        try {
          await hrmService.deletePayrollPeriod(periodId!)
          toast.success('Periode payroll berhasil dihapus')
          navigate('/hrm/payroll')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus periode payroll')
        }
      },
      variant: 'danger' as const,
    },
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Hrm/PayrollDetailPage.tsx
git commit -m "feat(hrm): add delete action to PayrollDetailPage"
```
