import { useState } from 'react'
import { Plus } from 'lucide-react'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useRBAC } from '@/lib/auth/useRBAC'
import { useRooms } from '@/lib/api/location'
import RoomCard from './RoomCard'
import RoomForm from './RoomForm'
import RoomAvailability from './RoomAvailability'
import type { Room } from '@/types/room'

interface Props {
  buildingId: string
}

type Selection = { kind: 'none' } | { kind: 'new' } | { kind: 'edit'; id: string }

export default function RoomsSection({ buildingId }: Props) {
  const { canAccess } = useRBAC()
  const { data, isLoading } = useRooms(buildingId)
  const [selection, setSelection] = useState<Selection>({ kind: 'none' })

  const rooms: Room[] = data ?? []
  const selected =
    selection.kind === 'edit'
      ? rooms.find((r) => r.id === selection.id)
      : undefined

  if (isLoading) return <LoadingSpinner size="lg" />

  const canCreate = canAccess('create', 'room')

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div className="lg:col-span-1 space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-neutral-700">
            Rooms ({rooms.length})
          </h2>
          <RoleGate action="create" resource="room">
            <Button size="sm" onClick={() => setSelection({ kind: 'new' })}>
              <Plus className="w-4 h-4" /> Add
            </Button>
          </RoleGate>
        </div>

        {rooms.length === 0 ? (
          <div className="text-sm text-neutral-500 p-4 border border-dashed border-neutral-200 rounded-lg text-center">
            No rooms yet.
            {canCreate && ' Add the first room to start.'}
          </div>
        ) : (
          <div className="space-y-2">
            {rooms.map((r) => (
              <RoomCard
                key={r.id}
                room={r}
                selected={selection.kind === 'edit' && selection.id === r.id}
                onSelect={() => setSelection({ kind: 'edit', id: r.id })}
              />
            ))}
          </div>
        )}
      </div>

      <div className="lg:col-span-2">
        {selection.kind === 'none' && (
          <div className="text-sm text-neutral-500 p-8 border border-dashed border-neutral-200 rounded-lg text-center">
            {rooms.length === 0
              ? 'Click + Add to create the first room.'
              : 'Select a room to edit, or click + Add to create a new one.'}
          </div>
        )}

        {selection.kind === 'new' && canCreate && (
          <div className="bg-white border border-neutral-100 rounded-xl p-5">
            <RoomForm
              buildingId={buildingId}
              mode={{ kind: 'create' }}
              onSuccess={() => setSelection({ kind: 'none' })}
              onCancel={() => setSelection({ kind: 'none' })}
            />
          </div>
        )}

        {selection.kind === 'edit' && selected && (
          <div className="space-y-4">
            <div className="bg-white border border-neutral-100 rounded-xl p-5">
              <RoomForm
                buildingId={buildingId}
                mode={{ kind: 'edit', room: selected }}
                onSuccess={() => setSelection({ kind: 'none' })}
                onCancel={() => setSelection({ kind: 'none' })}
              />
            </div>
            <div className="bg-white border border-neutral-100 rounded-xl p-5">
              <RoomAvailability roomId={selected.id} />
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
