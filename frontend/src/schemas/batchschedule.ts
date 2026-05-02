import { z } from 'zod'

export const MIN_DURATION_MINUTES = 15
export const MAX_DURATION_MINUTES = 12 * 60 // 12 hours

// Local datetime string accepted by <input type="datetime-local">: "YYYY-MM-DDTHH:mm"
const LOCAL_DATETIME = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?$/

export const createBatchScheduleSchema = z.object({
  module_id: z.string().uuid('module_id wajib UUID'),
  room_id: z.string().uuid('room_id wajib UUID'),
  scheduled_at: z
    .string()
    .min(1, 'Waktu wajib diisi')
    .regex(LOCAL_DATETIME, 'Format waktu tidak valid'),
  duration_minutes: z
    .number()
    .int()
    .min(MIN_DURATION_MINUTES, `Durasi minimal ${MIN_DURATION_MINUTES} menit`)
    .max(MAX_DURATION_MINUTES, `Durasi maksimal ${MAX_DURATION_MINUTES / 60} jam`),
  notes: z.string().max(500).default(''),
})

export type CreateBatchScheduleInput = z.infer<typeof createBatchScheduleSchema>
