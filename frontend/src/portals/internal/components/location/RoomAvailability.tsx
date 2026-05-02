import { useMemo } from 'react'
import { useRoomAvailability } from '@/lib/api/location'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface Props {
  roomId: string
}

function buildRange() {
  const from = new Date()
  from.setHours(0, 0, 0, 0)
  const to = new Date(from)
  to.setDate(to.getDate() + 7)
  return { from: from.toISOString(), to: to.toISOString() }
}

export default function RoomAvailability({ roomId }: Props) {
  const range = useMemo(buildRange, [])
  const { data, isLoading } = useRoomAvailability(roomId, range)

  if (isLoading) return <LoadingSpinner size="sm" />

  const slots = data?.slots ?? []

  return (
    <div className="space-y-2">
      <h4 className="text-xs font-semibold text-neutral-500 uppercase">
        Availability (next 7 days)
      </h4>
      {slots.length === 0 ? (
        <div className="text-sm text-neutral-500 p-3 border border-dashed border-neutral-200 rounded-lg text-center">
          No bookings in the next 7 days.
        </div>
      ) : (
        <ul className="space-y-1.5 max-h-64 overflow-y-auto">
          {slots.map((s, i) => (
            <li
              key={`${s.start}-${i}`}
              className="flex items-center justify-between text-xs px-3 py-2 rounded-md border border-neutral-200 bg-white"
            >
              <span className="text-neutral-700">
                {new Date(s.start).toLocaleString()} →{' '}
                {new Date(s.end).toLocaleTimeString()}
              </span>
              <span
                className={
                  s.status === 'booked'
                    ? 'text-red-600 font-medium'
                    : 'text-green-600 font-medium'
                }
              >
                {s.status}
              </span>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
