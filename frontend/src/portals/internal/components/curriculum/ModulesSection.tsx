import { useState } from 'react'
import { Plus, Lock } from 'lucide-react'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useCourseModules } from '@/lib/api/curriculum'
import ModuleList from './ModuleList'
import ModuleForm from './ModuleForm'
import type { CourseModule } from '@/types/coursemodule'
import type { CourseVersion } from '@/types/courseversion'

interface Props {
  version: CourseVersion
}

type FormState =
  | { open: false }
  | { open: true; mode: 'create' }
  | { open: true; mode: 'edit'; module: CourseModule }

export default function ModulesSection({ version }: Props) {
  const locked = version.status === 'approved' || version.status === 'archived'
  const { data: modules } = useCourseModules(version.id)
  const [form, setForm] = useState<FormState>({ open: false })

  const count = modules?.length ?? 0
  const nextSequence = count + 1

  function close() {
    setForm({ open: false })
  }

  return (
    <div className="space-y-3 pt-4 border-t border-neutral-100">
      <div className="flex items-center justify-between">
        <h4 className="text-sm font-semibold text-neutral-700">
          Modules ({count})
        </h4>
        {locked ? (
          <span className="inline-flex items-center gap-1.5 text-xs text-neutral-500">
            <Lock className="w-3.5 h-3.5" /> Version {version.status} — read-only
          </span>
        ) : (
          <RoleGate action="create" resource="coursemodule">
            <Button size="sm" onClick={() => setForm({ open: true, mode: 'create' })}>
              <Plus className="w-4 h-4" /> Add Module
            </Button>
          </RoleGate>
        )}
      </div>

      <ModuleList
        versionId={version.id}
        locked={locked}
        onEdit={(m) => setForm({ open: true, mode: 'edit', module: m })}
      />

      {form.open && (
        <div className="bg-white border border-neutral-200 rounded-xl p-5">
          <ModuleForm
            versionId={version.id}
            mode={
              form.mode === 'create'
                ? { kind: 'create', defaultSequence: nextSequence }
                : { kind: 'edit', module: form.module }
            }
            onSuccess={close}
            onCancel={close}
          />
        </div>
      )}
    </div>
  )
}
