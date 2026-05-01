# Batch Enrollment Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow students to enroll in a course batch from the student portal via a 3-step modal on the CourseDetail page.

**Architecture:** CourseCatalog's disabled button becomes a Link to CourseDetail. CourseDetail renders an EnrollmentModal (Radix Dialog) with 3 steps: batch selection → confirm + voucher → success. Two new components live in `frontend/src/portals/student/components/`. No backend changes needed — all required endpoints already exist.

**Tech Stack:** React 18, TypeScript, TanStack Query v5, Radix UI Dialog, Tailwind CSS, react-router-dom v6

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Modify | `frontend/src/lib/api/catalog.ts` | Add `label` field to `Batch` interface |
| Create | `frontend/src/portals/student/components/BatchCard.tsx` | Single batch selection card atom |
| Create | `frontend/src/portals/student/components/EnrollmentModal.tsx` | 3-step enrollment modal |
| Modify | `frontend/src/portals/student/pages/CourseCatalog.tsx` | Button → Link to CourseDetail |
| Modify | `frontend/src/portals/student/pages/CourseDetail.tsx` | Wire EnrollmentModal |

---

## Task 1: Fix Batch Interface — Add `label` Field

**Files:**
- Modify: `frontend/src/lib/api/catalog.ts`

Backend `catalog.course_batches` has a `label` column. The frontend `Batch` interface is missing it. All downstream code uses `batch.code` as identifier — `label` is the human-readable name shown in UI.

- [ ] **Step 1: Add `label` to `Batch` interface**

In `frontend/src/lib/api/catalog.ts`, find the `Batch` interface and add `label`:

```ts
export interface Batch {
  id: string
  course_id: string
  label: string        // ← add this line
  code: string
  start_date: string
  end_date: string
  max_students: number
  enrolled_count: number
  price: number
  status: 'draft' | 'open' | 'full' | 'ongoing' | 'completed' | 'cancelled'
}
```

- [ ] **Step 2: Type-check to verify no errors**

```bash
cd frontend && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors (existing code only reads `id`, `code`, `status`, `price` — adding `label` is non-breaking).

- [ ] **Step 3: Commit**

```bash
git add frontend/src/lib/api/catalog.ts
git commit -m "fix(catalog): add label field to Batch interface"
```

---

## Task 2: Create BatchCard Component

**Files:**
- Create: `frontend/src/portals/student/components/BatchCard.tsx`

A card that displays one batch and allows selection. Used in Step 1 of EnrollmentModal.

- [ ] **Step 1: Create the file**

Create `frontend/src/portals/student/components/BatchCard.tsx`:

```tsx
import { CheckCircle2 } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import StatusBadge from '@/components/shared/StatusBadge'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import type { Batch } from '@/lib/api/catalog'

interface BatchCardProps {
  batch: Batch
  selected: boolean
  onSelect: () => void
}

export default function BatchCard({ batch, selected, onSelect }: BatchCardProps) {
  const isSelectable = batch.status === 'open'

  return (
    <button
      type="button"
      onClick={isSelectable ? onSelect : undefined}
      disabled={!isSelectable}
      className={cn(
        'w-full text-left rounded-xl border p-4 transition-all',
        'shadow-[0_1px_3px_rgba(0,0,0,0.06)]',
        isSelectable
          ? 'cursor-pointer hover:border-brand-300 hover:shadow-md'
          : 'cursor-not-allowed opacity-50 bg-neutral-50',
        selected
          ? 'border-brand-500 ring-2 ring-brand-500/20 bg-brand-50/30'
          : 'border-neutral-100 bg-white',
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="space-y-1 flex-1 min-w-0">
          <p className="font-semibold text-sm text-neutral-900 truncate">
            {batch.label}
          </p>
          <p className="text-xs text-neutral-500">
            {formatDate(batch.start_date)} – {formatDate(batch.end_date)}
          </p>
          <p className="text-sm font-bold text-brand-700">
            {formatCurrency(batch.price)}
          </p>
        </div>
        <div className="flex flex-col items-end gap-2 shrink-0">
          <StatusBadge status={batch.status} variant="batch" />
          {selected && (
            <CheckCircle2 className="w-5 h-5 text-brand-600" />
          )}
        </div>
      </div>
    </button>
  )
}
```

- [ ] **Step 2: Type-check**

```bash
cd frontend && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/student/components/BatchCard.tsx
git commit -m "feat(student): add BatchCard component for batch selection"
```

---

## Task 3: Create EnrollmentModal Component

**Files:**
- Create: `frontend/src/portals/student/components/EnrollmentModal.tsx`

3-step modal using Radix Dialog. Steps: `'batches' | 'confirm' | 'success'`.

**Dependencies available:**
- `@radix-ui/react-dialog` — already used in `frontend/src/portals/internal/pages/Vouchers.tsx`
- `useBatches(courseId)` from `@/lib/api/catalog`
- `useCreateEnrollment()` from `@/lib/api/enrollment` — payload: `{ student_id, batch_id, voucher_code? }`
- `useAuth()` from `@/lib/auth/useAuth` — provides `user.id`
- `useNavigate` from `react-router-dom`

- [ ] **Step 1: Create the file**

Create `frontend/src/portals/student/components/EnrollmentModal.tsx`:

```tsx
import { useState } from 'react'
import * as Dialog from '@radix-ui/react-dialog'
import { X, Loader2, CheckCircle2 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useBatches, type Batch } from '@/lib/api/catalog'
import { useCreateEnrollment } from '@/lib/api/enrollment'
import { useAuth } from '@/lib/auth/useAuth'
import { formatCurrency } from '@/lib/utils/format'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import BatchCard from './BatchCard'

type Step = 'batches' | 'confirm' | 'success'

interface EnrollmentModalProps {
  open: boolean
  onClose: () => void
  courseId: string
  courseName: string
  courseFormat: string
}

export default function EnrollmentModal({
  open,
  onClose,
  courseId,
  courseName,
  courseFormat: _courseFormat,
}: EnrollmentModalProps) {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [step, setStep] = useState<Step>('batches')
  const [selectedBatch, setSelectedBatch] = useState<Batch | null>(null)
  const [voucherCode, setVoucherCode] = useState('')
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [enrolledBatchLabel, setEnrolledBatchLabel] = useState('')

  const { data: batches, isLoading: loadingBatches } = useBatches(courseId)
  const enrollMutation = useCreateEnrollment()

  function handleClose() {
    setStep('batches')
    setSelectedBatch(null)
    setVoucherCode('')
    setSubmitError(null)
    onClose()
  }

  async function handleSubmit() {
    if (!selectedBatch || !user) return
    setSubmitError(null)
    try {
      await enrollMutation.mutateAsync({
        student_id: user.id,
        batch_id: selectedBatch.id,
        voucher_code: voucherCode.trim() || undefined,
      })
      setEnrolledBatchLabel(selectedBatch.label)
      setStep('success')
    } catch (err: unknown) {
      const msg =
        err instanceof Error ? err.message : 'Enrollment failed. Please try again.'
      setSubmitError(msg)
    }
  }

  const openBatches = (batches ?? []).filter((b) => b.status === 'open')

  return (
    <Dialog.Root open={open} onOpenChange={(v) => { if (!v) handleClose() }}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
        <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-lg bg-white rounded-2xl shadow-2xl flex flex-col max-h-[90vh]">

          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-neutral-100 shrink-0">
            <div>
              <Dialog.Title className="font-semibold text-neutral-900 text-sm">
                {step === 'batches' && 'Select a Batch'}
                {step === 'confirm' && 'Confirm Enrollment'}
                {step === 'success' && 'Enrollment Confirmed'}
              </Dialog.Title>
              <p className="text-xs text-neutral-500 mt-0.5 truncate max-w-xs">{courseName}</p>
            </div>
            {step !== 'success' && (
              <button
                type="button"
                onClick={handleClose}
                className="p-1.5 rounded-lg hover:bg-neutral-100 transition-colors text-neutral-500"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Step indicator */}
          <div className="flex items-center justify-center gap-2 px-6 pt-4 shrink-0">
            {(['batches', 'confirm', 'success'] as Step[]).map((s, i) => (
              <div key={s} className="flex items-center gap-2">
                <div
                  className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-semibold transition-colors ${
                    step === s
                      ? 'bg-brand-600 text-white'
                      : i < ['batches', 'confirm', 'success'].indexOf(step)
                        ? 'bg-brand-100 text-brand-700'
                        : 'bg-neutral-100 text-neutral-400'
                  }`}
                >
                  {i + 1}
                </div>
                {i < 2 && <div className="w-8 h-px bg-neutral-200" />}
              </div>
            ))}
          </div>

          {/* Body */}
          <div className="flex-1 overflow-y-auto px-6 py-4">

            {/* Step 1: Batch Selection */}
            {step === 'batches' && (
              <div className="space-y-3">
                {loadingBatches ? (
                  <LoadingSpinner className="py-12" />
                ) : openBatches.length === 0 ? (
                  <EmptyState
                    title="No open batches"
                    description="There are no open batches available for this course right now. Check back later."
                  />
                ) : (
                  <>
                    <p className="text-xs text-neutral-500">
                      Choose the batch you want to join.
                    </p>
                    {(batches ?? []).map((batch) => (
                      <BatchCard
                        key={batch.id}
                        batch={batch}
                        selected={selectedBatch?.id === batch.id}
                        onSelect={() => setSelectedBatch(batch)}
                      />
                    ))}
                  </>
                )}
              </div>
            )}

            {/* Step 2: Confirm & Voucher */}
            {step === 'confirm' && selectedBatch && (
              <div className="space-y-4">
                <div className="rounded-xl border border-neutral-100 p-4 bg-neutral-50 space-y-2">
                  <p className="text-sm font-semibold text-neutral-900">{selectedBatch.label}</p>
                  <p className="text-xs text-neutral-500">
                    {selectedBatch.start_date} – {selectedBatch.end_date}
                  </p>
                  <p className="text-lg font-bold text-brand-700">
                    {formatCurrency(selectedBatch.price)}
                  </p>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-medium text-neutral-700">
                    Voucher code <span className="text-neutral-400 font-normal">(optional)</span>
                  </label>
                  <input
                    type="text"
                    value={voucherCode}
                    onChange={(e) => setVoucherCode(e.target.value)}
                    placeholder="e.g. SAVE20"
                    className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                  />
                </div>

                {submitError && (
                  <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
                    {submitError}
                  </p>
                )}
              </div>
            )}

            {/* Step 3: Success */}
            {step === 'success' && (
              <div className="flex flex-col items-center text-center py-6 space-y-3">
                <div className="w-16 h-16 rounded-full bg-emerald-100 flex items-center justify-center">
                  <CheckCircle2 className="w-8 h-8 text-emerald-600" />
                </div>
                <h3 className="text-base font-bold text-neutral-900">You're enrolled!</h3>
                <p className="text-sm text-neutral-600">
                  Successfully enrolled in <span className="font-semibold">{enrolledBatchLabel}</span>.
                </p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="px-6 py-4 border-t border-neutral-100 shrink-0 flex justify-between gap-3">
            {step === 'batches' && (
              <>
                <button
                  type="button"
                  onClick={handleClose}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-900 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={!selectedBatch}
                  onClick={() => setStep('confirm')}
                  className="px-5 py-2 rounded-lg bg-brand-600 text-white text-sm font-semibold disabled:opacity-40 disabled:cursor-not-allowed hover:bg-brand-700 transition-colors"
                >
                  Next →
                </button>
              </>
            )}

            {step === 'confirm' && (
              <>
                <button
                  type="button"
                  onClick={() => { setSubmitError(null); setStep('batches') }}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-900 transition-colors"
                >
                  ← Back
                </button>
                <button
                  type="button"
                  disabled={enrollMutation.isPending}
                  onClick={handleSubmit}
                  className="inline-flex items-center gap-2 px-5 py-2 rounded-lg bg-brand-600 text-white text-sm font-semibold disabled:opacity-40 disabled:cursor-not-allowed hover:bg-brand-700 transition-colors"
                >
                  {enrollMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
                  Confirm Enrollment
                </button>
              </>
            )}

            {step === 'success' && (
              <button
                type="button"
                onClick={() => { handleClose(); navigate('/student/enrollments') }}
                className="w-full px-5 py-2.5 rounded-lg bg-brand-600 text-white text-sm font-semibold hover:bg-brand-700 transition-colors"
              >
                View My Enrollments
              </button>
            )}
          </div>

        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
```

- [ ] **Step 2: Type-check**

```bash
cd frontend && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/student/components/EnrollmentModal.tsx
git commit -m "feat(student): add EnrollmentModal — 3-step batch enrollment flow"
```

---

## Task 4: Update CourseCatalog — Button → Link

**Files:**
- Modify: `frontend/src/portals/student/pages/CourseCatalog.tsx`

Replace the disabled "View batches →" button with a `Link` to `/student/courses/{course.id}`.

- [ ] **Step 1: Add Link import**

In `CourseCatalog.tsx`, add `Link` to the imports at the top of the file:

```tsx
import { Link } from 'react-router-dom'
```

- [ ] **Step 2: Replace disabled button with Link**

Find this block (around line 119):

```tsx
<div className="pt-2 border-t border-neutral-50">
  <button
    disabled
    className="w-full py-2 text-xs font-semibold text-neutral-400 rounded-lg cursor-not-allowed"
    title="Batch enrollment coming soon"
  >
    View batches →
  </button>
</div>
```

Replace with:

```tsx
<div className="pt-2 border-t border-neutral-50">
  <Link
    to={`/student/courses/${course.id}`}
    className="block w-full py-2 text-xs font-semibold text-center text-brand-600 hover:text-brand-700 rounded-lg hover:bg-brand-50 transition-colors"
  >
    View batches →
  </Link>
</div>
```

- [ ] **Step 3: Type-check**

```bash
cd frontend && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/portals/student/pages/CourseCatalog.tsx
git commit -m "feat(student): enable View batches link in CourseCatalog"
```

---

## Task 5: Update CourseDetail — Wire EnrollmentModal

**Files:**
- Modify: `frontend/src/portals/student/pages/CourseDetail.tsx`

Replace the placeholder "Enroll now" `<Link to="/student/catalog">` with a button that opens `EnrollmentModal`.

- [ ] **Step 1: Add imports**

In `CourseDetail.tsx`, add to existing imports:

```tsx
import { useState } from 'react'
import EnrollmentModal from '../components/EnrollmentModal'
```

Note: `useState` may already be imported — check and add only if missing.

- [ ] **Step 2: Add modal state**

Inside the `CourseDetail` function body, after the existing hooks (after `const activeIndex = ...`), add:

```tsx
const [enrollOpen, setEnrollOpen] = useState(false)
```

- [ ] **Step 3: Replace placeholder CTA with button**

Find this block in the JSX (the "Enroll now" link when `!enrollment`):

```tsx
<Link
  to="/student/catalog"
  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-white text-brand-700 font-semibold text-sm shadow-md hover:shadow-lg hover:scale-[1.02] active:scale-95 transition-all"
>
  <GraduationCap className="w-4 h-4" />
  Enroll now
</Link>
```

Replace with:

```tsx
<button
  type="button"
  onClick={() => setEnrollOpen(true)}
  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-white text-brand-700 font-semibold text-sm shadow-md hover:shadow-lg hover:scale-[1.02] active:scale-95 transition-all"
>
  <GraduationCap className="w-4 h-4" />
  Enroll now
</button>
```

- [ ] **Step 4: Add EnrollmentModal to JSX**

At the bottom of the returned JSX, just before the closing `</div>` of the root `<div className="space-y-6">`, add:

```tsx
<EnrollmentModal
  open={enrollOpen}
  onClose={() => setEnrollOpen(false)}
  courseId={id}
  courseName={course.name}
  courseFormat={course.format}
/>
```

- [ ] **Step 5: Remove unused Link import if no longer used**

Check if `Link` is still used elsewhere in `CourseDetail.tsx` (it is used for "Back to catalog"). Leave it if so.

- [ ] **Step 6: Type-check**

```bash
cd frontend && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 7: Build to verify no bundle errors**

```bash
cd frontend && npm run build 2>&1 | tail -15
```

Expected: successful build, no errors.

- [ ] **Step 8: Commit**

```bash
git add frontend/src/portals/student/pages/CourseDetail.tsx
git commit -m "feat(student): wire EnrollmentModal to CourseDetail Enroll now button"
```

---

## Task 6: Final Verification

- [ ] **Step 1: Run type-check one final time**

```bash
cd frontend && npx tsc --noEmit 2>&1
```

Expected: zero errors.

- [ ] **Step 2: Run build**

```bash
cd frontend && npm run build 2>&1 | tail -10
```

Expected: build success.

- [ ] **Step 3: Run existing tests**

```bash
cd frontend && npm test -- --run 2>&1 | tail -15
```

Expected: all pass (no regressions from catalog or enrollment changes).

- [ ] **Step 4: Verify route exists**

```bash
grep -n "courses/:id" frontend/src/App.tsx
```

Expected: line containing `path="courses/:id"` and `StudentCourseDetail`.
