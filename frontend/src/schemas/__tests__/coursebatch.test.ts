import { describe, it, expect } from 'vitest'
import {
  createCourseBatchSchema,
  updateCourseBatchSchema,
  assignFacilitatorSchema,
  PAYMENT_METHODS,
} from '../coursebatch'

const VALID_CREATE = {
  course_id: '11111111-1111-1111-1111-111111111111',
  code: 'B-01',
  name: 'Batch Web Dev Jan 2026',
  start_date: '2026-01-10',
  end_date: '2026-03-10',
  min_participants: 5,
  max_participants: 20,
  website_visible: true,
  is_active: true,
  price: 5000000,
  payment_method: 'upfront' as const,
}

describe('createCourseBatchSchema', () => {
  it('accepts valid input', () => {
    const r = createCourseBatchSchema.safeParse(VALID_CREATE)
    expect(r.success).toBe(true)
  })

  it('rejects non-UUID course_id', () => {
    const r = createCourseBatchSchema.safeParse({ ...VALID_CREATE, course_id: 'nope' })
    expect(r.success).toBe(false)
  })

  it('rejects empty name', () => {
    const r = createCourseBatchSchema.safeParse({ ...VALID_CREATE, name: '' })
    expect(r.success).toBe(false)
  })

  it('rejects start_date after end_date', () => {
    const r = createCourseBatchSchema.safeParse({
      ...VALID_CREATE,
      start_date: '2026-04-01',
      end_date: '2026-03-01',
    })
    expect(r.success).toBe(false)
  })

  it('rejects min_participants greater than max_participants', () => {
    const r = createCourseBatchSchema.safeParse({
      ...VALID_CREATE,
      min_participants: 30,
      max_participants: 20,
    })
    expect(r.success).toBe(false)
  })

  it('rejects negative price', () => {
    const r = createCourseBatchSchema.safeParse({ ...VALID_CREATE, price: -1 })
    expect(r.success).toBe(false)
  })

  it('rejects invalid payment_method', () => {
    const r = createCourseBatchSchema.safeParse({ ...VALID_CREATE, payment_method: 'cash' })
    expect(r.success).toBe(false)
  })

  it('exposes all 5 PAYMENT_METHODS', () => {
    expect(PAYMENT_METHODS).toHaveLength(5)
    for (const pm of PAYMENT_METHODS) {
      const r = createCourseBatchSchema.safeParse({ ...VALID_CREATE, payment_method: pm })
      expect(r.success).toBe(true)
    }
  })

  it('rejects bad date format', () => {
    const r = createCourseBatchSchema.safeParse({ ...VALID_CREATE, start_date: '10/01/2026' })
    expect(r.success).toBe(false)
  })
})

describe('updateCourseBatchSchema', () => {
  it('does not require course_id', () => {
    const { course_id: _ignored, ...rest } = VALID_CREATE
    void _ignored
    const r = updateCourseBatchSchema.safeParse(rest)
    expect(r.success).toBe(true)
  })
})

describe('assignFacilitatorSchema', () => {
  it('accepts UUID', () => {
    const r = assignFacilitatorSchema.safeParse({
      facilitator_id: '22222222-2222-2222-2222-222222222222',
    })
    expect(r.success).toBe(true)
  })

  it('rejects non-UUID', () => {
    const r = assignFacilitatorSchema.safeParse({ facilitator_id: 'abc' })
    expect(r.success).toBe(false)
  })
})
