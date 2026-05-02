import { useState, FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { useCreateFinanceInvoice } from '@/lib/api/invoice'
import { createInvoiceSchema } from '@/schemas/invoice'

interface FormState {
  student_id: string
  course_batch_id: string
  amount: string
  due_date: string
  notes: string
}

const INITIAL_STATE: FormState = {
  student_id: '',
  course_batch_id: '',
  amount: '',
  due_date: '',
  notes: '',
}

export default function InvoiceCreatePage() {
  const navigate = useNavigate()
  const create = useCreateFinanceInvoice()
  const [form, setForm] = useState<FormState>(INITIAL_STATE)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const update = (key: keyof FormState) => (e: { target: { value: string } }) =>
    setForm((f) => ({ ...f, [key]: e.target.value }))

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    const parsed = createInvoiceSchema.safeParse({
      student_id: form.student_id || undefined,
      course_batch_id: form.course_batch_id || undefined,
      amount: Number(form.amount) || 0,
      due_date: form.due_date,
      notes: form.notes,
    })
    if (!parsed.success) {
      const errs: Record<string, string> = {}
      for (const issue of parsed.error.issues) {
        errs[String(issue.path[0])] = issue.message
      }
      setErrors(errs)
      return
    }
    try {
      await create.mutateAsync(parsed.data)
      toast.success('Invoice created')
      navigate('/internal/invoices')
    } catch {
      toast.error('Failed to create invoice')
    }
  }

  return (
    <div className="max-w-2xl mx-auto py-8 px-4">
      <h1 className="text-xl font-semibold text-neutral-900 mb-6">New Invoice</h1>
      <form onSubmit={handleSubmit} className="space-y-4 bg-white p-6 rounded-xl border border-neutral-200">
        <Field label="Student ID (UUID)" error={errors.student_id}>
          <input
            type="text"
            value={form.student_id}
            onChange={update('student_id')}
            className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
            placeholder="optional if course_batch_id provided"
          />
        </Field>
        <Field label="Course Batch ID (UUID)" error={errors.course_batch_id}>
          <input
            type="text"
            value={form.course_batch_id}
            onChange={update('course_batch_id')}
            className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
            placeholder="optional if student_id provided"
          />
        </Field>
        <Field label="Amount (IDR)" error={errors.amount}>
          <input
            type="number"
            min={0}
            value={form.amount}
            onChange={update('amount')}
            className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
            required
          />
        </Field>
        <Field label="Due Date" error={errors.due_date}>
          <input
            type="date"
            value={form.due_date}
            onChange={update('due_date')}
            className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
            required
          />
        </Field>
        <Field label="Notes" error={errors.notes}>
          <textarea
            value={form.notes}
            onChange={update('notes')}
            rows={3}
            className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
          />
        </Field>
        <div className="flex justify-end gap-2 pt-4">
          <button
            type="button"
            onClick={() => navigate('/internal/invoices')}
            className="px-4 py-2 text-sm font-medium text-neutral-700 bg-neutral-100 rounded-lg hover:bg-neutral-200"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={create.isPending}
            className="px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50"
          >
            {create.isPending ? 'Creating…' : 'Create Invoice'}
          </button>
        </div>
      </form>
    </div>
  )
}

function Field({
  label,
  error,
  children,
}: {
  label: string
  error?: string
  children: React.ReactNode
}) {
  return (
    <label className="block">
      <span className="block text-sm font-medium text-neutral-700 mb-1">{label}</span>
      {children}
      {error && <span className="block mt-1 text-xs text-red-600">{error}</span>}
    </label>
  )
}
