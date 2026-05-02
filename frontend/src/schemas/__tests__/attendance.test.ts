import { describe, it, expect } from 'vitest'
import {
  attendanceMarkSchema,
  submitAttendanceSchema,
  ATTENDANCE_STATUSES,
  ATTENDANCE_STATUS_LABELS,
} from '../attendance'

const VALID_UUID = '11111111-1111-1111-1111-111111111111'

describe('attendanceMarkSchema', () => {
  it('accepts a valid mark with all fields', () => {
    const r = attendanceMarkSchema.safeParse({
      student_id: VALID_UUID,
      status: 'present',
      note: 'On time',
    })
    expect(r.success).toBe(true)
  })

  it('accepts a valid mark without note', () => {
    const r = attendanceMarkSchema.safeParse({
      student_id: VALID_UUID,
      status: 'absent',
    })
    expect(r.success).toBe(true)
  })

  it('rejects invalid status values', () => {
    const r = attendanceMarkSchema.safeParse({
      student_id: VALID_UUID,
      status: 'maybe',
    })
    expect(r.success).toBe(false)
  })

  it('rejects non-UUID student_id', () => {
    const r = attendanceMarkSchema.safeParse({
      student_id: 'not-a-uuid',
      status: 'present',
    })
    expect(r.success).toBe(false)
  })
})

describe('submitAttendanceSchema', () => {
  it('rejects empty marks array', () => {
    const r = submitAttendanceSchema.safeParse({ marks: [] })
    expect(r.success).toBe(false)
  })

  it('accepts non-empty marks array', () => {
    const r = submitAttendanceSchema.safeParse({
      marks: [{ student_id: VALID_UUID, status: 'late' }],
    })
    expect(r.success).toBe(true)
  })
})

describe('ATTENDANCE_STATUS_LABELS', () => {
  it('has a label for every status', () => {
    for (const s of ATTENDANCE_STATUSES) {
      expect(ATTENDANCE_STATUS_LABELS[s]).toBeTruthy()
    }
  })
})
