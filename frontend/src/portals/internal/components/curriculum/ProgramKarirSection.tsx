import { isProgramKarir } from '@/lib/utils/coursetype'
import InternshipConfigForm from './InternshipConfigForm'
import CharacterTestConfigForm from './CharacterTestConfigForm'
import type { CourseVersion } from '@/types/courseversion'

interface Props {
  version: CourseVersion
  courseTypeName?: string | null
}

export default function ProgramKarirSection({ version, courseTypeName }: Props) {
  if (!isProgramKarir(courseTypeName)) return null

  const locked = version.status === 'approved' || version.status === 'archived'

  return (
    <div className="space-y-3 pt-4 border-t border-neutral-100">
      <h4 className="text-sm font-semibold text-neutral-700">
        Program Karir Configuration
      </h4>
      <InternshipConfigForm versionId={version.id} locked={locked} />
      <CharacterTestConfigForm versionId={version.id} locked={locked} />
    </div>
  )
}
