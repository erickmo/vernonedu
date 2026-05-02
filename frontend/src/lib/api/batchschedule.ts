import { useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { CreateBatchScheduleInput } from '@/schemas/batchschedule'

const BATCHES_BASE = '/course-batches'

interface CreateBatchSchedulePayload {
  module_id: string
  room_id: string
  scheduled_at: string // ISO 8601 (UTC)
  duration_minutes: number
  notes?: string
}

/**
 * Convert form input (datetime-local "YYYY-MM-DDTHH:mm" in user's local tz)
 * to an ISO 8601 string the backend can parse as time.Time.
 */
export function toIsoFromLocal(localDateTime: string): string {
  // new Date("2026-05-10T09:00") interprets as local time → toISOString gives UTC.
  return new Date(localDateTime).toISOString()
}

export function useCreateBatchSchedule(batchId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateBatchScheduleInput) => {
      const payload: CreateBatchSchedulePayload = {
        module_id: input.module_id,
        room_id: input.room_id,
        scheduled_at: toIsoFromLocal(input.scheduled_at),
        duration_minutes: input.duration_minutes,
        notes: input.notes,
      }
      return apiClient
        .post(`${BATCHES_BASE}/${batchId}/schedules`, payload)
        .then((r) => r.data)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['coursebatches', batchId, 'schedules'] })
    },
  })
}

// Re-export the existing list hook so all schedule data lives in one module too.
export { useBatchSchedules } from './coursebatch'
