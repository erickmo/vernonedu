import { z } from 'zod'

export const ATTENDANCE_STATUSES = ['present', 'late', 'absent', 'excused'] as const

export const ATTENDANCE_STATUS_LABELS: Record<(typeof ATTENDANCE_STATUSES)[number], string> = {
  present: 'Hadir',
  late: 'Terlambat',
  absent: 'Tidak Hadir',
  excused: 'Izin',
}

export const attendanceMarkSchema = z.object({
  student_id: z.string().uuid('student_id must be a UUID'),
  status: z.enum(ATTENDANCE_STATUSES),
  note: z.string().max(500).optional(),
})

export const submitAttendanceSchema = z.object({
  marks: z.array(attendanceMarkSchema).min(1, 'At least one mark required'),
})

export type AttendanceMarkInput = z.infer<typeof attendanceMarkSchema>
export type SubmitAttendanceInput = z.infer<typeof submitAttendanceSchema>
