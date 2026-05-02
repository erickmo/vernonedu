import { z } from 'zod'

export const COMMON_FACILITIES = [
  'Projector',
  'Whiteboard',
  'AC',
  'Computers',
  'WiFi',
  'Sound System',
  'Smart TV',
] as const

export const createRoomSchema = z.object({
  building_id: z.string().uuid('Building wajib'),
  name: z.string().min(1, 'Name wajib').max(200),
  capacity: z
    .number({ invalid_type_error: 'Capacity harus angka' })
    .int()
    .positive('Capacity harus > 0')
    .nullable()
    .optional(),
  floor: z.string().max(50).nullable().optional(),
  facilities: z.array(z.string().min(1)).default([]),
  description: z.string().max(1000).default(''),
})

export const updateRoomSchema = createRoomSchema.omit({ building_id: true })

export type CreateRoomInput = z.infer<typeof createRoomSchema>
export type UpdateRoomInput = z.infer<typeof updateRoomSchema>
