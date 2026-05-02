import { describe, it, expect } from 'vitest'
import { createMasterCourseSchema, FIELDS } from '../mastercourse'

describe('createMasterCourseSchema', () => {
  it('accepts minimal valid input', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'Web Development',
      field: 'Tech',
    })
    expect(r.success).toBe(true)
  })

  it('rejects empty course_code', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: '',
      course_name: 'X',
      field: 'Tech',
    })
    expect(r.success).toBe(false)
  })

  it('rejects empty course_name', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: '',
      field: 'Tech',
    })
    expect(r.success).toBe(false)
  })

  it('rejects unknown field', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'X',
      field: 'Magic',
    })
    expect(r.success).toBe(false)
  })

  it('accepts empty supporting_app_url', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'X',
      field: 'Tech',
      supporting_app_url: '',
    })
    expect(r.success).toBe(true)
  })

  it('accepts valid url', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'X',
      field: 'Tech',
      supporting_app_url: 'https://example.com',
    })
    expect(r.success).toBe(true)
  })

  it('rejects malformed url', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'X',
      field: 'Tech',
      supporting_app_url: 'not-a-url',
    })
    expect(r.success).toBe(false)
  })

  it('exports FIELDS readonly tuple of 5', () => {
    expect(FIELDS).toHaveLength(5)
  })
})
