export interface BatchSchedule {
  id: string
  course_batch_id: string
  module_id: string | null
  room_id: string | null
  scheduled_at: string
  end_time: string
  duration_minutes: number
  notes: string
  status: string
}
