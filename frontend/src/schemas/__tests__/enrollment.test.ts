import { describe, it, expect } from 'vitest'
import { createEnrollmentSchema, updateEnrollmentSchema } from '../enrollment'

const VALID_CREATE = {
  student_id: '11111111-1111-1111-1111-111111111111',
  course_batch_id: '22222222-2222-2222-2222-222222222222',
  enrollment_date: '2026-05-01',
  payment_method: 'upfront' as const,
  voucher_code: '',
}

describe('createEnrollmentSchema', () => {
  it('accepts a valid payload', () => {
    expect(createEnrollmentSchema.safeParse(VALID_CREATE).success).toBe(true)
  })

  it('rejects non-UUID student_id', () => {
    const r = createEnrollmentSchema.safeParse({ ...VALID_CREATE, student_id: 'not-a-uuid' })
    expect(r.success).toBe(false)
  })

  it('rejects non-UUID course_batch_id', () => {
    const r = createEnrollmentSchema.safeParse({ ...VALID_CREATE, course_batch_id: 'xx' })
    expect(r.success).toBe(false)
  })

  it('rejects malformed enrollment_date', () => {
    const r = createEnrollmentSchema.safeParse({ ...VALID_CREATE, enrollment_date: '01-05-2026' })
    expect(r.success).toBe(false)
  })

  it('rejects unknown payment_method', () => {
    const r = createEnrollmentSchema.safeParse({ ...VALID_CREATE, payment_method: 'cash' })
    expect(r.success).toBe(false)
  })

  it('allows optional voucher_code to be omitted', () => {
    const { voucher_code: _omit, ...rest } = VALID_CREATE
    expect(createEnrollmentSchema.safeParse(rest).success).toBe(true)
  })
})

describe('updateEnrollmentSchema', () => {
  it('accepts a valid status + payment_status pair', () => {
    const r = updateEnrollmentSchema.safeParse({ status: 'confirmed', payment_status: 'paid' })
    expect(r.success).toBe(true)
  })

  it('rejects unknown status', () => {
    const r = updateEnrollmentSchema.safeParse({ status: 'archived', payment_status: 'paid' })
    expect(r.success).toBe(false)
  })

  it('rejects unknown payment_status', () => {
    const r = updateEnrollmentSchema.safeParse({ status: 'confirmed', payment_status: 'late' })
    expect(r.success).toBe(false)
  })
})
