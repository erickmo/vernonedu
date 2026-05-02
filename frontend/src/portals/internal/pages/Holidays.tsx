import { useMemo, useState } from 'react'
import { Trash2 } from 'lucide-react'
import { useHolidays, useCreateHoliday, useDeleteHoliday } from '@/lib/api/settings'
import { createHolidaySchema } from '@/schemas/holiday'
import type { Holiday } from '@/types/holiday'
import Button from '@/components/ui/Button'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import RoleGate from '@/components/shared/RoleGate'

const YEAR_RANGE_PAST = 5
const YEAR_RANGE_FUTURE = 5

function buildYearOptions(current: number): number[] {
  const start = current - YEAR_RANGE_PAST
  const end = current + YEAR_RANGE_FUTURE
  const out: number[] = []
  for (let y = start; y <= end; y++) out.push(y)
  return out
}

function formatDate(iso: string): string {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return iso
  return d.toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

export default function Holidays() {
  const currentYear = new Date().getFullYear()
  const [year, setYear] = useState<number>(currentYear)
  const [date, setDate] = useState('')
  const [name, setName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pendingDelete, setPendingDelete] = useState<Holiday | null>(null)

  const yearOptions = useMemo(() => buildYearOptions(currentYear), [currentYear])

  const { data, isLoading } = useHolidays(year)
  const createM = useCreateHoliday()
  const deleteM = useDeleteHoliday()

  const sorted = useMemo(
    () => [...(data ?? [])].sort((a, b) => a.date.localeCompare(b.date)),
    [data],
  )

  function resetForm() {
    setDate('')
    setName('')
    setError(null)
  }

  async function handleAdd(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    const parsed = createHolidaySchema.safeParse({ date, name })
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    try {
      await createM.mutateAsync(parsed.data)
      resetForm()
    } catch (err: unknown) {
      const msg =
        err && typeof err === 'object' && 'message' in err
          ? String((err as { message: unknown }).message)
          : 'Failed to create holiday'
      setError(msg)
    }
  }

  async function handleConfirmDelete() {
    if (!pendingDelete) return
    try {
      await deleteM.mutateAsync(pendingDelete.id)
    } finally {
      setPendingDelete(null)
    }
  }

  return (
    <div className="p-6 space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-neutral-900">Holidays</h1>
          <p className="text-sm text-neutral-500">
            Configure non-working days. Sessions cannot be scheduled on these dates.
          </p>
        </div>
        <select
          value={year}
          onChange={(e) => setYear(Number(e.target.value))}
          className="px-3 py-2 text-sm border border-neutral-200 rounded-lg"
          aria-label="Select year"
        >
          {yearOptions.map((y) => (
            <option key={y} value={y}>
              {y}
            </option>
          ))}
        </select>
      </header>

      <RoleGate action="create" resource="holiday">
        <form
          onSubmit={handleAdd}
          className="flex flex-wrap items-end gap-3 p-4 bg-white border border-neutral-200 rounded-xl"
        >
          <div className="flex flex-col">
            <label className="text-xs text-neutral-500 mb-1">Date</label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="px-3 py-2 text-sm border border-neutral-200 rounded-lg"
              required
            />
          </div>
          <div className="flex flex-col flex-1 min-w-[200px]">
            <label className="text-xs text-neutral-500 mb-1">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Labor Day"
              className="px-3 py-2 text-sm border border-neutral-200 rounded-lg"
              required
            />
          </div>
          <Button type="submit" disabled={createM.isPending}>
            {createM.isPending ? 'Adding…' : 'Add Holiday'}
          </Button>
          {error && (
            <p className="basis-full text-sm text-red-600">{error}</p>
          )}
        </form>
      </RoleGate>

      <div className="bg-white border border-neutral-200 rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-neutral-50 text-left text-xs uppercase text-neutral-500">
            <tr>
              <th className="px-4 py-3 w-48">Date</th>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3 w-24 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr>
                <td colSpan={3} className="px-4 py-8 text-center text-neutral-500">
                  Loading…
                </td>
              </tr>
            )}
            {!isLoading && sorted.length === 0 && (
              <tr>
                <td colSpan={3} className="px-4 py-8 text-center text-neutral-500">
                  No holidays configured for {year}.
                </td>
              </tr>
            )}
            {!isLoading &&
              sorted.map((h) => (
                <tr key={h.id} className="border-t border-neutral-100">
                  <td className="px-4 py-3 font-mono text-neutral-700">
                    {formatDate(h.date)}
                  </td>
                  <td className="px-4 py-3 text-neutral-900">{h.name}</td>
                  <td className="px-4 py-3 text-right">
                    <RoleGate action="delete" resource="holiday">
                      <button
                        onClick={() => setPendingDelete(h)}
                        className="inline-flex items-center justify-center p-2 rounded-lg text-red-600 hover:bg-red-50"
                        aria-label={`Delete ${h.name}`}
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </RoleGate>
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
      </div>

      <ConfirmDialog
        open={!!pendingDelete}
        title="Delete holiday?"
        description={
          pendingDelete
            ? `Remove "${pendingDelete.name}" on ${formatDate(pendingDelete.date)}? This cannot be undone.`
            : ''
        }
        confirmLabel="Delete"
        destructive
        onCancel={() => setPendingDelete(null)}
        onConfirm={handleConfirmDelete}
      />
    </div>
  )
}
