import { describe, it, expect } from 'vitest'
import { createHolidaySchema } from '../holiday'

describe('createHolidaySchema', () => {
  it('accepts valid input', () => {
    const r = createHolidaySchema.safeParse({ date: '2026-05-01', name: 'Labor Day' })
    expect(r.success).toBe(true)
  })

  it('rejects empty name', () => {
    const r = createHolidaySchema.safeParse({ date: '2026-05-01', name: '' })
    expect(r.success).toBe(false)
  })

  it('rejects malformed date', () => {
    const r = createHolidaySchema.safeParse({ date: '01/05/2026', name: 'X' })
    expect(r.success).toBe(false)
  })

  it('rejects invalid calendar date', () => {
    const r = createHolidaySchema.safeParse({ date: '2026-13-40', name: 'X' })
    expect(r.success).toBe(false)
  })

  it('rejects name longer than 120 chars', () => {
    const r = createHolidaySchema.safeParse({
      date: '2026-05-01',
      name: 'a'.repeat(121),
    })
    expect(r.success).toBe(false)
  })
})
