import { describe, it, expect } from 'vitest'
import {
  componentFailureConfigSchema,
  DEFAULT_FAILURE_CONFIG,
} from '../failureconfig'
import { createCourseModuleSchema } from '../coursemodule'

const VALID_UUID = '11111111-1111-1111-1111-111111111111'

const VALID_MODULE = {
  module_code: 'CODE-001',
  module_title: 'Reference Module',
  duration_hours: 4,
  sequence: 1,
  content_depth: '',
  topics: [],
  practical_activities: [],
  assessment_method: '',
  tools_required: [],
  requirements: [],
  is_reference: false,
  ref_module_id: null,
}

describe('componentFailureConfigSchema', () => {
  it('accepts default config', () => {
    const r = componentFailureConfigSchema.safeParse(DEFAULT_FAILURE_CONFIG)
    expect(r.success).toBe(true)
  })

  it('rejects invalid pembelajaran enum', () => {
    const r = componentFailureConfigSchema.safeParse({
      ...DEFAULT_FAILURE_CONFIG,
      pembelajaran: 'unknown',
    })
    expect(r.success).toBe(false)
  })

  it('rejects continue_no_cert for character_test', () => {
    const r = componentFailureConfigSchema.safeParse({
      ...DEFAULT_FAILURE_CONFIG,
      character_test: 'continue_no_cert',
    })
    expect(r.success).toBe(false)
  })

  it('accepts continue_no_talentpool for character_test', () => {
    const r = componentFailureConfigSchema.safeParse({
      ...DEFAULT_FAILURE_CONFIG,
      character_test: 'continue_no_talentpool',
    })
    expect(r.success).toBe(true)
  })

  it('rejects missing fields', () => {
    const r = componentFailureConfigSchema.safeParse({ pembelajaran: 'retry' })
    expect(r.success).toBe(false)
  })
})

describe('createCourseModuleSchema reference fields', () => {
  it('accepts non-reference module without ref_module_id', () => {
    expect(createCourseModuleSchema.safeParse(VALID_MODULE).success).toBe(true)
  })

  it('rejects reference module without ref_module_id', () => {
    const r = createCourseModuleSchema.safeParse({
      ...VALID_MODULE,
      is_reference: true,
      ref_module_id: null,
    })
    expect(r.success).toBe(false)
  })

  it('accepts reference module with valid uuid ref_module_id', () => {
    const r = createCourseModuleSchema.safeParse({
      ...VALID_MODULE,
      is_reference: true,
      ref_module_id: VALID_UUID,
    })
    expect(r.success).toBe(true)
  })

  it('rejects reference module with non-uuid ref_module_id', () => {
    const r = createCourseModuleSchema.safeParse({
      ...VALID_MODULE,
      is_reference: true,
      ref_module_id: 'not-a-uuid',
    })
    expect(r.success).toBe(false)
  })
})
