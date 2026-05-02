import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { ChevronDown, ChevronRight, Plus, Target } from 'lucide-react'
import { toast } from 'sonner'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import StatusBadge from '@/components/shared/StatusBadge'
import {
  useObjectives, useCreateObjective, useCreateKeyResult, useUpdateKeyResultProgress,
} from '@/lib/api/okr'
import {
  createObjectiveSchema, createKeyResultSchema,
  type CreateObjectiveInput, type CreateKeyResultInput,
} from '@/schemas/okr'
import { OKR_LEVELS, OKR_STATUSES, type Objective, type KeyResult } from '@/types/okr'

const FULL_PROGRESS = 100
const ZERO = 0

function calcProgress(kr: KeyResult): number {
  if (kr.target <= 0) return 0
  return Math.min(FULL_PROGRESS, Math.max(ZERO, Math.round((kr.current / kr.target) * FULL_PROGRESS)))
}

export default function OKR() {
  const [filterLevel, setFilterLevel] = useState('')
  const [showCreateObj, setShowCreateObj] = useState(false)
  const { data, isLoading } = useObjectives({ level: (filterLevel as any) || '' })

  return (
    <div className="space-y-5">
      <PageHeader
        title="OKR"
        subtitle="Objectives & Key Results — company → individual"
        actions={
          <RoleGate action="create" resource="okr">
            <Button onClick={() => setShowCreateObj(true)}>
              <Plus className="w-4 h-4" /> Add Objective
            </Button>
          </RoleGate>
        }
      />

      <div className="flex gap-3 items-center">
        <span className="text-xs font-semibold text-neutral-500 uppercase">Level</span>
        <select
          value={filterLevel}
          onChange={(e) => setFilterLevel(e.target.value)}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
        >
          <option value="">All levels</option>
          {OKR_LEVELS.map((l) => <option key={l} value={l}>{l}</option>)}
        </select>
      </div>

      {showCreateObj && (
        <CreateObjectiveForm
          onClose={() => setShowCreateObj(false)}
        />
      )}

      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <div className="space-y-3">
          {(data?.data ?? []).length === 0 ? (
            <div className="text-sm text-neutral-500 bg-white border border-neutral-100 rounded-xl p-6 text-center">
              No objectives yet
            </div>
          ) : (
            (data?.data ?? []).map((obj) => <ObjectiveRow key={obj.id} obj={obj} />)
          )}
        </div>
      )}
    </div>
  )
}

function CreateObjectiveForm({ onClose }: { onClose: () => void }) {
  const create = useCreateObjective()
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<CreateObjectiveInput>({
    resolver: zodResolver(createObjectiveSchema),
    defaultValues: { level: 'company', status: 'draft', period: '' },
  })

  async function onSubmit(values: CreateObjectiveInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Objective created')
      onClose()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="bg-white border border-neutral-200 rounded-xl p-5 space-y-3 max-w-2xl">
      <h3 className="text-sm font-semibold text-neutral-900">New Objective</h3>
      <div className="grid grid-cols-2 gap-3">
        <FormField label="Title" required error={errors.title?.message}>
          <Input {...register('title')} />
        </FormField>
        <FormField label="Period" required error={errors.period?.message}>
          <Input {...register('period')} placeholder="Q1 2026" />
        </FormField>
        <FormField label="Owner ID" required error={errors.owner_id?.message}>
          <Input {...register('owner_id')} />
        </FormField>
        <FormField label="Owner Name" required error={errors.owner_name?.message}>
          <Input {...register('owner_name')} />
        </FormField>
        <FormField label="Level" required error={errors.level?.message}>
          <Select {...register('level')}>
            {OKR_LEVELS.map((l) => <option key={l} value={l}>{l}</option>)}
          </Select>
        </FormField>
        <FormField label="Status" error={errors.status?.message}>
          <Select {...register('status')}>
            {OKR_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </Select>
        </FormField>
      </div>
      <div className="flex gap-2 pt-2">
        <Button type="button" variant="secondary" onClick={onClose}>Cancel</Button>
        <Button type="submit" loading={isSubmitting}>Save</Button>
      </div>
    </form>
  )
}

function ObjectiveRow({ obj }: { obj: Objective }) {
  const [expanded, setExpanded] = useState(false)
  const [showKR, setShowKR] = useState(false)
  const krs = obj.key_results ?? []
  const progress = obj.progress ?? (
    krs.length === 0 ? 0 : Math.round(krs.reduce((s, k) => s + calcProgress(k), 0) / krs.length)
  )

  return (
    <div className="bg-white border border-neutral-200 rounded-xl">
      <button
        onClick={() => setExpanded((e) => !e)}
        className="w-full flex items-center gap-3 p-4 text-left hover:bg-neutral-50 rounded-xl"
      >
        {expanded ? <ChevronDown className="w-4 h-4 text-neutral-400" /> : <ChevronRight className="w-4 h-4 text-neutral-400" />}
        <Target className="w-4 h-4 text-brand-600" />
        <div className="flex-1 min-w-0">
          <div className="text-sm font-semibold text-neutral-900 truncate">{obj.title}</div>
          <div className="text-xs text-neutral-500">{obj.level} · {obj.period} · {obj.owner_name}</div>
        </div>
        <div className="flex items-center gap-2">
          <StatusBadge status={obj.status} />
          <ProgressBar value={progress} />
        </div>
      </button>

      {expanded && (
        <div className="border-t border-neutral-100 p-4 space-y-2">
          {krs.length === 0 ? (
            <div className="text-xs text-neutral-400">No key results yet</div>
          ) : (
            krs.map((kr) => <KeyResultRow key={kr.id} kr={kr} />)
          )}
          <div className="pt-2">
            {showKR ? (
              <CreateKeyResultForm objectiveId={obj.id} onClose={() => setShowKR(false)} />
            ) : (
              <RoleGate action="create" resource="okr">
                <button
                  onClick={() => setShowKR(true)}
                  className="text-xs text-brand-600 hover:underline flex items-center gap-1"
                >
                  <Plus className="w-3 h-3" /> Add Key Result
                </button>
              </RoleGate>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

function CreateKeyResultForm({ objectiveId, onClose }: { objectiveId: string; onClose: () => void }) {
  const create = useCreateKeyResult()
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<CreateKeyResultInput>({
    resolver: zodResolver(createKeyResultSchema),
    defaultValues: { objective_id: objectiveId, current: 0, target: 1 },
  })

  async function onSubmit(values: CreateKeyResultInput) {
    try {
      await create.mutateAsync({ ...values, objective_id: objectiveId })
      toast.success('Key result added')
      onClose()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to add KR')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="grid grid-cols-12 gap-2 items-end bg-neutral-50 rounded-lg p-3">
      <div className="col-span-5">
        <FormField label="Title" required error={errors.title?.message}>
          <Input {...register('title')} />
        </FormField>
      </div>
      <div className="col-span-2">
        <FormField label="Target" required error={errors.target?.message}>
          <Input type="number" step="any" {...register('target', { valueAsNumber: true })} />
        </FormField>
      </div>
      <div className="col-span-2">
        <FormField label="Current" error={errors.current?.message}>
          <Input type="number" step="any" {...register('current', { valueAsNumber: true })} />
        </FormField>
      </div>
      <div className="col-span-2">
        <FormField label="Unit">
          <Input {...register('unit')} placeholder="MOU, %, ..." />
        </FormField>
      </div>
      <div className="col-span-1 flex gap-1">
        <Button type="submit" loading={isSubmitting}>Save</Button>
      </div>
      <div className="col-span-12">
        <button type="button" className="text-xs text-neutral-500 hover:underline" onClick={onClose}>Cancel</button>
      </div>
    </form>
  )
}

function KeyResultRow({ kr }: { kr: KeyResult }) {
  const update = useUpdateKeyResultProgress()
  const [current, setCurrent] = useState(kr.current)
  const progress = calcProgress({ ...kr, current })

  async function save() {
    if (current === kr.current) return
    try {
      await update.mutateAsync({ id: kr.id, input: { current } })
      toast.success('Progress updated')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  return (
    <div className="flex items-center gap-3 py-2 px-2 hover:bg-neutral-50 rounded-md">
      <div className="flex-1 text-sm text-neutral-800">{kr.title}</div>
      <RoleGate
        action="update"
        resource="okr"
        fallback={<span className="text-xs text-neutral-500">{kr.current} / {kr.target} {kr.unit ?? ''}</span>}
      >
        <input
          type="number"
          value={current}
          onChange={(e) => setCurrent(parseFloat(e.target.value) || 0)}
          onBlur={save}
          className="w-20 px-2 py-1 text-xs border border-neutral-200 rounded"
        />
        <span className="text-xs text-neutral-400">/ {kr.target} {kr.unit ?? ''}</span>
      </RoleGate>
      <ProgressBar value={progress} />
    </div>
  )
}

function ProgressBar({ value }: { value: number }) {
  return (
    <div className="flex items-center gap-2 w-32">
      <div className="flex-1 h-1.5 bg-neutral-100 rounded-full overflow-hidden">
        <div className="h-full bg-brand-500" style={{ width: `${value}%` }} />
      </div>
      <span className="text-xs text-neutral-600 w-8 text-right">{value}%</span>
    </div>
  )
}
