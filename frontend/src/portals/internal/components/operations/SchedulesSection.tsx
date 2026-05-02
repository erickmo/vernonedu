import { useState } from 'react'
import { Plus } from 'lucide-react'
import { toast } from 'sonner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useBatchSchedules } from '@/lib/api/coursebatch'
import { useCreateBatchSchedule } from '@/lib/api/batchschedule'
import type { CreateBatchScheduleInput } from '@/schemas/batchschedule'
import type { CourseBatch } from '@/types/coursebatch'
import ScheduleList from './ScheduleList'
import ScheduleForm from './ScheduleForm'

interface Props {
  batch: CourseBatch
}

export default function SchedulesSection({ batch }: Props) {
  const [showForm, setShowForm] = useState(false)
  const { data: schedules, isLoading } = useBatchSchedules(batch.id)
  const create = useCreateBatchSchedule(batch.id)

  async function handleCreate(input: CreateBatchScheduleInput) {
    try {
      await create.mutateAsync(input)
      toast.success('Jadwal ditambahkan')
      setShowForm(false)
    } catch (e: any) {
      const status = e?.response?.status
      const msg = e?.response?.data?.message ?? 'Gagal menambahkan jadwal'
      if (status === 409) {
        toast.error(`Konflik ruangan: ${msg}`)
      } else {
        toast.error(msg)
      }
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-sm font-semibold text-neutral-800">Jadwal Sesi</h3>
          <p className="text-xs text-neutral-500">
            {schedules?.length ?? 0} sesi terjadwal untuk batch ini.
          </p>
        </div>
        <RoleGate action="create" resource="batchschedule">
          <Button onClick={() => setShowForm(true)}>
            <Plus className="w-4 h-4" /> Tambah Jadwal
          </Button>
        </RoleGate>
      </div>

      <ScheduleList schedules={schedules} loading={isLoading} />

      <ScheduleForm
        open={showForm}
        onClose={() => setShowForm(false)}
        onSubmit={handleCreate}
        loading={create.isPending}
        existing={schedules}
      />
    </div>
  )
}
