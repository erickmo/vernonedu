import { useMemo } from 'react'
import { toast } from 'sonner'
import { ChevronRight } from 'lucide-react'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import { useTalentPool, useUpdateTalentPoolStatus } from '@/lib/api/talentpool'
import type { TalentPoolEntry, TalentPoolStage } from '@/types/talentpool'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'HR', to: '/internal/hr' },
  { label: 'Talent Pool' },
]

const STAGES: { id: TalentPoolStage; label: string }[] = [
  { id: 'learning', label: 'Learning' },
  { id: 'internship', label: 'Internship' },
  { id: 'recommendation', label: 'Recommendation' },
  { id: 'test', label: 'Character Test' },
  { id: 'talentpool', label: 'Talent Pool' },
  { id: 'placed', label: 'Placed' },
]

const STAGE_INDEX: Record<TalentPoolStage, number> = {
  learning: 0,
  internship: 1,
  recommendation: 2,
  test: 3,
  talentpool: 4,
  placed: 5,
  inactive: 99,
}

function nextStage(current: TalentPoolStage): TalentPoolStage | null {
  const i = STAGE_INDEX[current]
  if (i >= 5 || i === 99) return null
  return STAGES[i + 1]?.id ?? null
}

export default function TalentPoolPage() {
  const { data, isLoading } = useTalentPool({ limit: 200 })
  const update = useUpdateTalentPoolStatus()

  const grouped = useMemo(() => {
    const map: Record<string, TalentPoolEntry[]> = {}
    for (const s of STAGES) map[s.id] = []
    for (const entry of data?.data ?? []) {
      if (map[entry.status]) map[entry.status].push(entry)
    }
    return map
  }, [data])

  async function advance(entry: TalentPoolEntry) {
    const next = nextStage(entry.status)
    if (!next) {
      toast.info('No next stage available')
      return
    }
    try {
      await update.mutateAsync({ id: entry.id, input: { status: next } })
      toast.success(`Advanced to ${next}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to advance stage')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Talent Pool"
      subtitle="Career program pipeline — learning to placement"
    >
      {isLoading ? (
        <div className="text-sm text-neutral-500">Loading…</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-3">
          {STAGES.map((stage) => (
            <div key={stage.id} className="bg-neutral-50 rounded-xl p-3 min-h-[300px]">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-semibold">{stage.label}</h3>
                <span className="text-xs text-neutral-500">
                  {grouped[stage.id]?.length ?? 0}
                </span>
              </div>
              <div className="space-y-2">
                {grouped[stage.id]?.map((entry) => (
                  <div
                    key={entry.id}
                    className="bg-white rounded-lg border border-neutral-200 p-3 text-sm"
                  >
                    <div className="font-medium truncate">
                      {entry.participant_name ?? entry.participant_id.slice(0, 8)}
                    </div>
                    {entry.master_course_name && (
                      <div className="text-xs text-neutral-500 truncate mt-0.5">
                        {entry.master_course_name}
                      </div>
                    )}
                    {nextStage(entry.status) && (
                      <button
                        onClick={() => advance(entry)}
                        disabled={update.isPending}
                        className="mt-2 inline-flex items-center gap-1 text-xs text-brand-600 hover:text-brand-700 disabled:opacity-50"
                      >
                        Advance Stage <ChevronRight className="w-3 h-3" />
                      </button>
                    )}
                  </div>
                ))}
                {(grouped[stage.id]?.length ?? 0) === 0 && (
                  <div className="text-xs text-neutral-400 text-center py-4">Empty</div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </StandardPageLayout>
  )
}
