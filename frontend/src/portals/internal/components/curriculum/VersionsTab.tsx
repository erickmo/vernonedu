import { useMemo, useState } from 'react'
import { Plus } from 'lucide-react'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import Select from '@/components/ui/Select'
import { useRBAC } from '@/lib/auth/useRBAC'
import { useCourseTypes, useCourseVersions } from '@/lib/api/curriculum'
import VersionTimeline from './VersionTimeline'
import VersionDetailPanel from './VersionDetailPanel'
import VersionForm from './VersionForm'
import type { CourseVersion } from '@/types/courseversion'

interface Props {
  courseId: string
}

const STATUS_RANK: Record<CourseVersion['status'], number> = {
  approved: 0, review: 1, draft: 2, archived: 3,
}

function sortVersions(list: CourseVersion[]): CourseVersion[] {
  return [...list].sort((a, b) => {
    const r = STATUS_RANK[a.status] - STATUS_RANK[b.status]
    if (r !== 0) return r
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })
}

export default function VersionsTab({ courseId }: Props) {
  const { canAccess } = useRBAC()
  const { data: types, isLoading: typesLoading } = useCourseTypes(courseId)
  const [typeId, setTypeId] = useState<string>('')

  const effectiveTypeId = typeId || types?.[0]?.id || ''
  const effectiveType = types?.find((t) => t.id === effectiveTypeId)
  const { data: rawVersions, isLoading: versionsLoading } = useCourseVersions(effectiveTypeId || undefined)
  const versions = useMemo(() => sortVersions(rawVersions ?? []), [rawVersions])

  const [selectedVersionId, setSelectedVersionId] = useState<string>()
  const [creating, setCreating] = useState(false)

  if (typesLoading) return <LoadingSpinner size="lg" />

  if (!types || types.length === 0) {
    return (
      <div className="text-sm text-neutral-500 p-8 border border-dashed border-neutral-200 rounded-lg text-center">
        Create a CourseType first (Variants tab) before adding versions.
      </div>
    )
  }

  const latest = versions[0]

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <label className="text-sm text-neutral-600">Course Type:</label>
          <Select
            value={effectiveTypeId}
            onChange={(e) => { setTypeId(e.target.value); setSelectedVersionId(undefined); setCreating(false) }}
            className="min-w-[200px]"
          >
            {types.map((t) => <option key={t.id} value={t.id}>{t.type_name}</option>)}
          </Select>
        </div>
        <RoleGate action="create" resource="courseversion">
          <Button size="sm" onClick={() => { setCreating(true); setSelectedVersionId(undefined) }}>
            <Plus className="w-4 h-4" /> Create New Version
          </Button>
        </RoleGate>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-1">
          {versionsLoading ? (
            <LoadingSpinner size="md" />
          ) : versions.length === 0 ? (
            <div className="text-sm text-neutral-500 p-4 border border-dashed border-neutral-200 rounded-lg text-center">
              No versions yet.
              {canAccess('create', 'courseversion') && ' Create the first version.'}
            </div>
          ) : (
            <VersionTimeline
              versions={versions}
              selectedId={selectedVersionId}
              onSelect={(id) => { setSelectedVersionId(id); setCreating(false) }}
            />
          )}
        </div>

        <div className="lg:col-span-2 bg-white border border-neutral-100 rounded-xl p-5">
          {creating ? (
            <VersionForm
              typeId={effectiveTypeId}
              latestVersion={latest}
              onSuccess={() => setCreating(false)}
              onCancel={() => setCreating(false)}
            />
          ) : selectedVersionId ? (
            <VersionDetailPanel
              versionId={selectedVersionId}
              typeId={effectiveTypeId}
              courseTypeName={effectiveType?.type_name}
            />
          ) : (
            <div className="text-sm text-neutral-500 p-8 text-center">
              {versions.length === 0
                ? 'Click + Create New Version to start.'
                : 'Select a version to see details.'}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
