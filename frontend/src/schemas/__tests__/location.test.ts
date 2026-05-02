import { describe, it, expect } from 'vitest'
import { createBuildingSchema, updateBuildingSchema } from '../building'
import { createRoomSchema, updateRoomSchema } from '../room'

const VALID_BUILDING = {
  name: 'Main Building',
  address: 'Jl. Sudirman 1',
  description: 'HQ',
}

const VALID_ROOM = {
  building_id: '00000000-0000-0000-0000-000000000001',
  name: 'Room 101',
  capacity: 30,
  floor: '1',
  facilities: ['Projector', 'AC'],
  description: '',
}

describe('createBuildingSchema', () => {
  it('accepts valid input', () => {
    const r = createBuildingSchema.safeParse(VALID_BUILDING)
    expect(r.success).toBe(true)
  })

  it('rejects empty name', () => {
    const r = createBuildingSchema.safeParse({ ...VALID_BUILDING, name: '' })
    expect(r.success).toBe(false)
  })

  it('accepts minimal input with default address/description', () => {
    const r = createBuildingSchema.safeParse({ name: 'X' })
    expect(r.success).toBe(true)
  })

  it('rejects name longer than 200 chars', () => {
    const r = createBuildingSchema.safeParse({ ...VALID_BUILDING, name: 'A'.repeat(201) })
    expect(r.success).toBe(false)
  })

  it('updateBuildingSchema parses valid input', () => {
    const r = updateBuildingSchema.safeParse(VALID_BUILDING)
    expect(r.success).toBe(true)
  })
})

describe('createRoomSchema', () => {
  it('accepts valid input', () => {
    const r = createRoomSchema.safeParse(VALID_ROOM)
    expect(r.success).toBe(true)
  })

  it('rejects non-UUID building_id', () => {
    const r = createRoomSchema.safeParse({ ...VALID_ROOM, building_id: 'not-uuid' })
    expect(r.success).toBe(false)
  })

  it('rejects empty room name', () => {
    const r = createRoomSchema.safeParse({ ...VALID_ROOM, name: '' })
    expect(r.success).toBe(false)
  })

  it('rejects negative capacity', () => {
    const r = createRoomSchema.safeParse({ ...VALID_ROOM, capacity: -5 })
    expect(r.success).toBe(false)
  })

  it('accepts null capacity', () => {
    const r = createRoomSchema.safeParse({ ...VALID_ROOM, capacity: null })
    expect(r.success).toBe(true)
  })

  it('defaults facilities to empty array', () => {
    const { facilities, ...rest } = VALID_ROOM
    void facilities
    const r = createRoomSchema.safeParse(rest)
    expect(r.success).toBe(true)
    if (r.success) expect(r.data.facilities).toEqual([])
  })

  it('updateRoomSchema does not require building_id', () => {
    const { building_id: _bid, ...rest } = VALID_ROOM
    void _bid
    const r = updateRoomSchema.safeParse(rest)
    expect(r.success).toBe(true)
  })
})
