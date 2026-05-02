export type AttendanceStatus = 'present' | 'late' | 'absent' | 'excused'

export interface AttendanceRecord {
  student_id: string
  student_name: string
  student_code?: string
  status: AttendanceStatus
  note?: string
}

export interface AttendanceMark {
  student_id: string
  status: AttendanceStatus
  note?: string
}

export interface SessionSummary {
  id: string
  batch_id: string
  batch_name?: string
  scheduled_at: string
  duration_minutes: number
  module_id?: string
  module_name?: string
  room_id?: string
  room_name?: string
  status: string
  attendance_taken?: boolean
}
