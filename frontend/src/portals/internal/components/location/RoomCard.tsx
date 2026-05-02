import { Users } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import type { Room } from '@/types/room'

interface Props {
  room: Room
  selected: boolean
  onSelect: () => void
}

export default function RoomCard({ room, selected, onSelect }: Props) {
  return (
    <button
      type="button"
      onClick={onSelect}
      className={cn(
        'w-full text-left p-3 rounded-lg border transition-colors',
        selected
          ? 'border-brand-600 bg-brand-50'
          : 'border-neutral-200 bg-white hover:border-neutral-300',
      )}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <div className="font-medium text-sm text-neutral-900 truncate">
            {room.name}
          </div>
          <div className="text-xs text-neutral-500 mt-0.5">
            {room.floor ? `Floor ${room.floor}` : 'No floor'}
            {room.capacity != null && (
              <span className="inline-flex items-center gap-1 ml-2">
                <Users className="w-3 h-3" /> {room.capacity}
              </span>
            )}
          </div>
          {room.facilities.length > 0 && (
            <div className="flex flex-wrap gap-1 mt-1.5">
              {room.facilities.slice(0, 4).map((f, i) => (
                <span
                  key={`${f}-${i}`}
                  className="px-1.5 py-0.5 text-[10px] bg-neutral-100 text-neutral-600 rounded"
                >
                  {f}
                </span>
              ))}
              {room.facilities.length > 4 && (
                <span className="text-[10px] text-neutral-500">
                  +{room.facilities.length - 4}
                </span>
              )}
            </div>
          )}
        </div>
      </div>
    </button>
  )
}
