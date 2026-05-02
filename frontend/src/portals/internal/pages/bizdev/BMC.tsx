import { useEffect, useMemo, useState } from 'react'
import { Save } from 'lucide-react'
import { toast } from 'sonner'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { BMC_COMPONENTS, type BMCComponent } from '@/types/bmc'
import { useBMC, useUpdateBMC } from '@/lib/api/bmc'

const TEXTAREA_ROWS = 8

function buildDefaults(existing: BMCComponent[] | undefined): BMCComponent[] {
  return BMC_COMPONENTS.map((meta) => {
    const found = existing?.find((c) => c.key === meta.key)
    return {
      key: meta.key,
      label: meta.label,
      content: found?.content ?? '',
      partner_count: found?.partner_count ?? 0,
    }
  })
}

export default function BMC() {
  const { data, isLoading } = useBMC()
  const update = useUpdateBMC()
  const [components, setComponents] = useState<BMCComponent[]>(() => buildDefaults([]))
  const [dirty, setDirty] = useState(false)

  useEffect(() => {
    if (!isLoading) {
      setComponents(buildDefaults(data?.components))
      setDirty(false)
    }
  }, [data, isLoading])

  const componentMap = useMemo(() => {
    const m: Record<string, BMCComponent> = {}
    components.forEach((c) => { m[c.key] = c })
    return m
  }, [components])

  function updateContent(key: string, content: string) {
    setComponents((prev) => prev.map((c) => (c.key === key ? { ...c, content } : c)))
    setDirty(true)
  }

  async function onSave() {
    try {
      await update.mutateAsync({ components })
      toast.success('Business Model Canvas saved')
      setDirty(false)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to save BMC')
    }
  }

  if (isLoading) return <LoadingSpinner size="lg" />

  return (
    <div className="space-y-5">
      <PageHeader
        title="Business Model Canvas"
        subtitle="Strategic blueprint — 9 components"
        actions={
          <RoleGate action="update" resource="bmc">
            <Button onClick={onSave} loading={update.isPending} disabled={!dirty || update.isPending}>
              <Save className="w-4 h-4" /> Save All
            </Button>
          </RoleGate>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
        {/* Row 1 */}
        <BMCCard className="lg:row-span-2" comp={componentMap.key_partners} abbr="KP" onChange={updateContent} />
        <div className="lg:row-span-2 grid grid-rows-2 gap-3">
          <BMCCard comp={componentMap.key_activities} abbr="KA" onChange={updateContent} />
          <BMCCard comp={componentMap.key_resources} abbr="KR" onChange={updateContent} />
        </div>
        <BMCCard className="lg:row-span-2" comp={componentMap.value_propositions} abbr="VP" onChange={updateContent} />
        <div className="lg:row-span-2 grid grid-rows-2 gap-3">
          <BMCCard comp={componentMap.customer_relationships} abbr="CR" onChange={updateContent} />
          <BMCCard comp={componentMap.channels} abbr="CH" onChange={updateContent} />
        </div>
        <BMCCard className="lg:row-span-2" comp={componentMap.customer_segments} abbr="CS" onChange={updateContent} />

        {/* Row 2 — costs + revenue full-width */}
        <div className="lg:col-span-5 grid grid-cols-1 md:grid-cols-2 gap-3">
          <BMCCard comp={componentMap.cost_structure} abbr="C$" onChange={updateContent} />
          <BMCCard comp={componentMap.revenue_streams} abbr="R$" onChange={updateContent} />
        </div>
      </div>
    </div>
  )
}

interface BMCCardProps {
  comp: BMCComponent | undefined
  abbr: string
  onChange: (key: string, content: string) => void
  className?: string
}

function BMCCard({ comp, abbr, onChange, className = '' }: BMCCardProps) {
  if (!comp) return null
  return (
    <div className={`bg-white border border-neutral-200 rounded-xl p-4 flex flex-col ${className}`}>
      <div className="flex items-center justify-between mb-2">
        <div>
          <span className="text-[10px] font-semibold text-brand-600 uppercase tracking-wider">{abbr}</span>
          <h3 className="text-sm font-semibold text-neutral-900">{comp.label}</h3>
        </div>
        {(comp.partner_count ?? 0) > 0 && (
          <span className="text-xs px-2 py-0.5 bg-brand-50 text-brand-700 rounded-full">
            {comp.partner_count} partner{comp.partner_count === 1 ? '' : 's'}
          </span>
        )}
      </div>
      <textarea
        value={comp.content}
        onChange={(e) => onChange(comp.key, e.target.value)}
        rows={TEXTAREA_ROWS}
        placeholder={`Add ${comp.label.toLowerCase()}…`}
        className="flex-1 w-full text-sm text-neutral-700 bg-transparent resize-none focus:outline-none focus:ring-2 focus:ring-brand-200 rounded-md p-2 border border-neutral-100"
      />
    </div>
  )
}
