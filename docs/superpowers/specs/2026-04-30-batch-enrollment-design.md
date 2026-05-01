# Batch Enrollment Flow — Spec

**Date:** 2026-04-30  
**Status:** Approved  
**Scope:** `frontend/src/portals/student/`

---

## Problem

Students can browse courses in the catalog and view course details, but cannot enroll. `CourseCatalog` has a disabled "View batches →" button. `CourseDetail` has an "Enroll now" button that links back to `/student/catalog` — a no-op placeholder.

---

## Solution

Two-part change:

1. **CourseCatalog** — replace disabled button with `Link` to `/student/courses/{id}`
2. **CourseDetail** — replace placeholder CTA with a 3-step enrollment modal

---

## User Flow

```
CourseCatalog
  └─ "View batches →" (Link)  →  /student/courses/{id}

CourseDetail
  └─ "Enroll now" button (shown only when NOT enrolled)
       ↓ onClick → open EnrollmentModal

EnrollmentModal
  ├─ Step 1: Batch Selection
  │     useBatches(courseId) → GET /api/v1/courses/{id}/batches
  │     Cards: label, date range, price, status
  │     Only "open" batches selectable; others greyed/disabled
  │     "Next →" enabled after selection
  │
  ├─ Step 2: Confirm & Voucher
  │     Show: selected batch summary + price
  │     Optional voucher code input (validated on submit only)
  │     Submit: POST /api/v1/enrollments
  │       { student_id, course_batch_id, format, mode: "individual",
  │         payer: "self", price: batch.price, voucher_code, source: "student_portal" }
  │
  └─ Step 3: Success
        "Enrolled in [batch.label]"
        Button: "View My Enrollments" → /student/enrollments
        On close: invalidate ['enrollments'] cache
```

---

## Component Structure

### New files

```
frontend/src/portals/student/components/
  EnrollmentModal.tsx    ← 3-step modal (step state machine + all step views)
  BatchCard.tsx          ← batch selection card atom
```

### Modified files

```
frontend/src/portals/student/pages/CourseCatalog.tsx
  - Import Link from react-router-dom
  - Replace <button disabled> with <Link to={`/student/courses/${course.id}`}>

frontend/src/portals/student/pages/CourseDetail.tsx
  - Import EnrollmentModal
  - Add: const [enrollOpen, setEnrollOpen] = useState(false)
  - Replace placeholder <Link to="/student/catalog"> CTA with:
      <button onClick={() => setEnrollOpen(true)}>Enroll now</button>
      <EnrollmentModal open={enrollOpen} onClose={() => setEnrollOpen(false)}
                       courseId={id} courseName={course.name} courseFormat={course.format} />
```

---

## EnrollmentModal Interface

```tsx
interface EnrollmentModalProps {
  open: boolean
  onClose: () => void
  courseId: string
  courseName: string
  courseFormat: string   // "online" | "offline" | "hybrid"
}
```

### Step state machine

```
type Step = 'batches' | 'confirm' | 'success'
```

### Step 1 — Batch Selection

- Data: `useBatches(courseId)` (existing hook, hits `GET /courses/{id}/batches`)
- Loading: spinner
- Empty (no batches or no open batches): `EmptyState` "No open batches available"
- Each batch card (`BatchCard`): label, `start_date – end_date`, `formatCurrency(batch.price)`, status badge
- Disabled if `batch.status !== 'open'`
- Selected state: brand-colored ring + checkmark
- "Next →" button: disabled until batch selected

### Step 2 — Confirm & Voucher

- Summary: batch label, date range, price
- Voucher input: optional, no pre-validation — error shown inline after submit
- Price display: `batch.price` (no client-side discount calculation — backend owns the final price)
- Submit button triggers `useCreateEnrollment()` mutation
- Error handling: inline error message below form (not toast)
- Loading: submit button shows spinner + disabled

### Step 3 — Success

- Heading: "You're enrolled!"
- Body: batch label + start date
- Button: "View My Enrollments" → `navigate('/student/enrollments')`
- On modal close (X or button): `queryClient.invalidateQueries({ queryKey: ['enrollments'] })`

---

## BatchCard Component

```tsx
interface BatchCardProps {
  batch: Batch
  selected: boolean
  onSelect: () => void
}
```

- Disabled + greyed when `batch.status !== 'open'`
- Visual: border card, brand ring when selected, checkmark icon top-right when selected
- Shows: label (bold), date range, price (formatted), status badge

---

## Edge Cases

| Case | Handling |
|---|---|
| No open batches | Step 1 EmptyState "No open batches available. Check back later." |
| All batches disabled | Same EmptyState |
| Duplicate enrollment | Backend 409 → inline error in Step 2: "Already enrolled in this batch" |
| Voucher invalid/expired | Backend 422 → inline error under voucher field |
| Batch closed mid-flow | Submit 400/409 → "Batch no longer available" + reset to Step 1 |
| Not logged in | `user` from `useAuth()` undefined → "Enroll now" button not rendered |

---

## Design System Constraints

- Modal: `fixed inset-0 z-50` overlay, `bg-white rounded-2xl shadow-2xl` panel, max-w-lg, centered
- Step indicator: 3 dots or numbered pills at top of modal (1 → 2 → 3)
- Consistent with existing design: Plus Jakarta Sans, brand-600 primary, `border-neutral-100` borders
- BatchCard: `bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]` — same as catalog cards

---

## Route Verification

`/student/courses/:id` already registered in `App.tsx:82`. No route changes needed.
