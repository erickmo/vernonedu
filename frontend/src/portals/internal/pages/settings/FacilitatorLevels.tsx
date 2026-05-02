import { useEffect, useState } from 'react'
import { toast } from 'sonner'
import { Plus, Trash2 } from 'lucide-react'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import Input from '@/components/ui/Input'
import Button from '@/components/ui/Button'
import {
  useFacilitatorLevels,
  useUpsertFacilitatorLevels,
} from '@/lib/api/settings-hr'
import { upsertFacilitatorLevelsSchema } from '@/schemas/facilitatorlevel'
import type { FacilitatorLevel } from '@/types/facilitatorlevel'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Settings', to: '/internal/settings' },
  { label: 'Facilitator Levels' },
]

export default function FacilitatorLevelsPage() {
  const { data, isLoading } = useFacilitatorLevels()
  const upsert = useUpsertFacilitatorLevels()
  const [rows, setRows] = useState<FacilitatorLevel[]>([])
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (data) setRows(data)
  }, [data])

  function update(idx: number, patch: Partial<FacilitatorLevel>) {
    setRows((rs) => rs.map((r, i) => (i === idx ? { ...r, ...patch } : r)))
  }

  function addRow() {
    const next = (rows[rows.length - 1]?.level ?? 0) + 1
    setRows([...rows, { level: next, name: '', fee_per_session: 0 }])
  }

  function removeRow(idx: number) {
    setRows((rs) => rs.filter((_, i) => i !== idx))
  }

  async function save() {
    setError(null)
    const parsed = upsertFacilitatorLevelsSchema.safeParse({ levels: rows })
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    try {
      await upsert.mutateAsync(parsed.data)
      toast.success('Facilitator levels updated')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Facilitator Levels"
      subtitle="Define level + fee per session for facilitators"
      actions={
        <Button onClick={save} loading={upsert.isPending}>
          Save
        </Button>
      }
    >
      <div className="max-w-3xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        {isLoading ? (
          <div className="text-sm text-neutral-500">Loading…</div>
        ) : (
          <>
            <div className="grid grid-cols-12 gap-2 text-xs font-medium text-neutral-500">
              <div className="col-span-2">Level</div>
              <div className="col-span-5">Name</div>
              <div className="col-span-4">Fee per Session (Rp)</div>
              <div className="col-span-1" />
            </div>
            {rows.map((row, i) => (
              <div key={i} className="grid grid-cols-12 gap-2 items-center">
                <div className="col-span-2">
                  <Input
                    type="number"
                    value={row.level}
                    onChange={(e) => update(i, { level: parseInt(e.target.value || '0', 10) })}
                  />
                </div>
                <div className="col-span-5">
                  <Input
                    value={row.name}
                    onChange={(e) => update(i, { name: e.target.value })}
                    placeholder="Junior / Senior / Master"
                  />
                </div>
                <div className="col-span-4">
                  <Input
                    type="number"
                    value={row.fee_per_session}
                    onChange={(e) =>
                      update(i, { fee_per_session: parseInt(e.target.value || '0', 10) })
                    }
                  />
                </div>
                <button
                  type="button"
                  className="col-span-1 text-red-600 hover:text-red-800 flex justify-center"
                  onClick={() => removeRow(i)}
                  aria-label="Remove row"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
            <Button variant="secondary" onClick={addRow}>
              <Plus className="w-4 h-4" /> Add Level
            </Button>
            {error && <div className="text-sm text-red-600">{error}</div>}
          </>
        )}
      </div>
    </StandardPageLayout>
  )
}
