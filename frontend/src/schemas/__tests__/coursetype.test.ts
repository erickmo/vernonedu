import { describe, it, expect } from 'vitest'
import { createCourseTypeSchema, TYPE_NAMES } from '../coursetype'

const VALID = {
  type_name: 'Reguler',
  price_type: 'one-time' as const,
  price_currency: 'IDR' as const,
  target_audience: '',
  certification_type: '',
  extra_docs: [],
  normal_price: 5000000,
  min_price: 3000000,
  min_participants: 10,
  max_participants: 25,
}

describe('createCourseTypeSchema', () => {
  it('accepts valid minimal input', () => {
    const r = createCourseTypeSchema.safeParse(VALID)
    expect(r.success).toBe(true)
  })

  it('rejects empty type_name', () => {
    const r = createCourseTypeSchema.safeParse({ ...VALID, type_name: '' })
    expect(r.success).toBe(false)
  })

  it('rejects min_price greater than normal_price', () => {
    const r = createCourseTypeSchema.safeParse({ ...VALID, min_price: 6000000, normal_price: 5000000 })
    expect(r.success).toBe(false)
    if (!r.success) {
      const issue = r.error.issues.find((i) => i.path[0] === 'min_price')
      expect(issue).toBeDefined()
    }
  })

  it('rejects min_participants greater than max_participants', () => {
    const r = createCourseTypeSchema.safeParse({ ...VALID, min_participants: 30, max_participants: 25 })
    expect(r.success).toBe(false)
    if (!r.success) {
      const issue = r.error.issues.find((i) => i.path[0] === 'min_participants')
      expect(issue).toBeDefined()
    }
  })

  it('rejects negative price', () => {
    const r = createCourseTypeSchema.safeParse({ ...VALID, normal_price: -1 })
    expect(r.success).toBe(false)
  })

  it('accepts all 5 standard TYPE_NAMES values', () => {
    expect(TYPE_NAMES).toHaveLength(5)
    for (const name of TYPE_NAMES) {
      const r = createCourseTypeSchema.safeParse({ ...VALID, type_name: name })
      expect(r.success).toBe(true)
    }
  })
})
