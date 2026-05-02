import { describe, it, expect } from 'vitest'
import {
  createBatchScheduleSchema,
  MIN_DURATION_MINUTES,
  MAX_DURATION_MINUTES,
} from '../batchschedule'

const VALID = {
  module_id: '11111111-1111-1111-1111-111111111111',
  room_id: '22222222-2222-2222-2222-222222222222',
  scheduled_at: '2026-05-10T09:00',
  duration_minutes: 120,
  notes: '',
}

describe('createBatchScheduleSchema', () => {
  it('accepts valid input', () => {
    const r = createBatchScheduleSchema.safeParse(VALID)
    expect(r.success).toBe(true)
  })

  it('rejects non-UUID module_id', () => {
    const r = createBatchScheduleSchema.safeParse({ ...VALID, module_id: 'nope' })
    expect(r.success).toBe(false)
  })

  it('rejects non-UUID room_id', () => {
    const r = createBatchScheduleSchema.safeParse({ ...VALID, room_id: 'nope' })
    expect(r.success).toBe(false)
  })

  it('rejects malformed scheduled_at', () => {
    const r = createBatchScheduleSchema.safeParse({ ...VALID, scheduled_at: '10/05/2026 09:00' })
    expect(r.success).toBe(false)
  })

  it(`rejects duration shorter than ${MIN_DURATION_MINUTES} min`, () => {
    const r = createBatchScheduleSchema.safeParse({ ...VALID, duration_minutes: 5 })
    expect(r.success).toBe(false)
  })

  it(`rejects duration longer than ${MAX_DURATION_MINUTES} min`, () => {
    const r = createBatchScheduleSchema.safeParse({
      ...VALID,
      duration_minutes: MAX_DURATION_MINUTES + 1,
    })
    expect(r.success).toBe(false)
  })

  it('rejects non-integer duration', () => {
    const r = createBatchScheduleSchema.safeParse({ ...VALID, duration_minutes: 60.5 })
    expect(r.success).toBe(false)
  })

  it('accepts datetime-local with seconds', () => {
    const r = createBatchScheduleSchema.safeParse({ ...VALID, scheduled_at: '2026-05-10T09:00:00' })
    expect(r.success).toBe(true)
  })
})
