import { useEffect, useState } from 'react'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import MultiInput from '@/components/shared/MultiInput'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  createRoomSchema,
  updateRoomSchema,
  type CreateRoomInput,
  type UpdateRoomInput,
} from '@/schemas/room'
import { useCreateRoom, useUpdateRoom, useDeleteRoom } from '@/lib/api/location'
import type { Room } from '@/types/room'

type Mode = { kind: 'create' } | { kind: 'edit'; room: Room }

interface Props {
  buildingId: string
  mode: Mode
  onSuccess: () => void
  onCancel: () => void
}

function buildDefaults(buildingId: string): CreateRoomInput {
  return {
    building_id: buildingId,
    name: '',
    capacity: null,
    floor: '',
    facilities: [],
    description: '',
  }
}

function roomToInput(r: Room, buildingId: string): CreateRoomInput {
  return {
    building_id: buildingId,
    name: r.name,
    capacity: r.capacity ?? null,
    floor: r.floor ?? '',
    facilities: r.facilities ?? [],
    description: r.description ?? '',
  }
}

export default function RoomForm({ buildingId, mode, onSuccess, onCancel }: Props) {
  const create = useCreateRoom(buildingId)
  const update = useUpdateRoom(buildingId)
  const del = useDeleteRoom(buildingId)
  const [confirmDelete, setConfirmDelete] = useState(false)

  const isEdit = mode.kind === 'edit'
  const schema = isEdit ? updateRoomSchema : createRoomSchema

  const {
    register, handleSubmit, control, reset,
    formState: { errors, isSubmitting },
  } = useForm<CreateRoomInput>({
    resolver: zodResolver(schema as any),
    defaultValues: isEdit ? roomToInput(mode.room, buildingId) : buildDefaults(buildingId),
  })

  useEffect(() => {
    if (isEdit) reset(roomToInput(mode.room, buildingId))
    else reset(buildDefaults(buildingId))
  }, [mode, buildingId, reset, isEdit])

  async function onSubmit(values: CreateRoomInput) {
    try {
      if (isEdit) {
        const { building_id: _bid, ...rest } = values
        void _bid
        await update.mutateAsync({ roomId: mode.room.id, input: rest as UpdateRoomInput })
        toast.success('Room updated')
      } else {
        await create.mutateAsync(values)
        toast.success('Room created')
      }
      onSuccess()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to save room')
    }
  }

  async function onDelete() {
    if (!isEdit) return
    try {
      await del.mutateAsync(mode.room.id)
      toast.success('Room deleted')
      onSuccess()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete')
    } finally {
      setConfirmDelete(false)
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="font-semibold text-neutral-900">
        {isEdit ? mode.room.name : 'New Room'}
      </h3>

      <FormField label="Name" required error={errors.name?.message}>
        <Input {...register('name')} placeholder="Room 101" />
      </FormField>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Capacity" error={errors.capacity?.message}>
          <Input
            type="number"
            min={1}
            {...register('capacity', {
              setValueAs: (v) => (v === '' || v == null ? null : Number(v)),
            })}
          />
        </FormField>
        <FormField label="Floor" error={errors.floor?.message}>
          <Input {...register('floor')} placeholder="1" />
        </FormField>
      </div>

      <FormField label="Facilities">
        <Controller
          name="facilities"
          control={control}
          render={({ field }) => (
            <MultiInput
              value={field.value ?? []}
              onChange={field.onChange}
              placeholder="e.g. Projector, Whiteboard, AC"
            />
          )}
        />
      </FormField>

      <FormField label="Description" error={errors.description?.message}>
        <Textarea {...register('description')} rows={3} />
      </FormField>

      <div className="flex gap-2 pt-2 border-t border-neutral-100">
        <Button type="button" variant="secondary" onClick={onCancel}>Cancel</Button>
        <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Save</Button>
        {isEdit && (
          <RoleGate action="delete" resource="room">
            <Button type="button" variant="danger" onClick={() => setConfirmDelete(true)}>
              Delete
            </Button>
          </RoleGate>
        )}
      </div>

      <ConfirmDialog
        open={confirmDelete}
        onConfirm={onDelete}
        onCancel={() => setConfirmDelete(false)}
        title="Delete room?"
        description="This action cannot be undone."
        confirmLabel="Delete"
        destructive
      />
    </form>
  )
}
