export interface Room {
  id: string
  building_id: string
  name: string
  capacity: number | null
  floor: string | null
  facilities: string[]
  description: string
  created_at: string
  updated_at: string
}

export interface RoomAvailabilitySlot {
  start: string
  end: string
  status: 'available' | 'booked'
  reference?: string
}

export interface RoomAvailability {
  room_id: string
  from: string
  to: string
  slots: RoomAvailabilitySlot[]
}
