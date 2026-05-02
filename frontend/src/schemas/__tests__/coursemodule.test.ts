import { describe, it, expect } from 'vitest'
import { createCourseModuleSchema, updateCourseModuleSchema } from '../coursemodule'

const VALID = {
  module_code: 'CODE-001',
  module_title: 'Pemrograman Dasar',
  duration_hours: 8,
  sequence: 1,
  content_depth: '',
  topics: [],
  practical_activities: [],
  assessment_method: '',
  tools_required: [],
  requirements: [],
  is_reference: false,
}

describe('createCourseModuleSchema', () => {
  it('accepts valid input', () => {
    expect(createCourseModuleSchema.safeParse(VALID).success).toBe(true)
  })
  it('rejects empty module_code', () => {
    expect(createCourseModuleSchema.safeParse({ ...VALID, module_code: '' }).success).toBe(false)
  })
  it('rejects empty module_title', () => {
    expect(createCourseModuleSchema.safeParse({ ...VALID, module_title: '' }).success).toBe(false)
  })
  it('rejects sequence <= 0', () => {
    expect(createCourseModuleSchema.safeParse({ ...VALID, sequence: 0 }).success).toBe(false)
  })
  it('rejects negative duration_hours', () => {
    expect(createCourseModuleSchema.safeParse({ ...VALID, duration_hours: -1 }).success).toBe(false)
  })
  it('accepts populated arrays', () => {
    const r = createCourseModuleSchema.safeParse({
      ...VALID,
      topics: ['Variables', 'Loops'],
      tools_required: ['VS Code'],
      requirements: ['Laptop'],
    })
    expect(r.success).toBe(true)
  })
})

describe('updateCourseModuleSchema', () => {
  it('does not include module_code or is_reference', () => {
    const keys = Object.keys(updateCourseModuleSchema.shape)
    expect(keys).not.toContain('module_code')
    expect(keys).not.toContain('is_reference')
    expect(keys).toContain('module_title')
    expect(keys).toContain('sequence')
  })
})
