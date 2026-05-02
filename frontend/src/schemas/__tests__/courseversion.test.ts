import { describe, it, expect } from 'vitest'
import {
  createCourseVersionSchema,
  promoteCourseVersionSchema,
  CHANGE_TYPES,
  nextVersion,
} from '../courseversion'

const VALID = {
  version_number: '1.0.0',
  change_type: 'minor' as const,
  changelog: 'Initial release with new modules',
}

describe('createCourseVersionSchema', () => {
  it('accepts valid input', () => {
    expect(createCourseVersionSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects invalid version format', () => {
    for (const bad of ['1.0', 'v1.0.0', '1.0.0-beta', 'abc']) {
      expect(createCourseVersionSchema.safeParse({ ...VALID, version_number: bad }).success).toBe(false)
    }
  })

  it('rejects changelog under 10 chars', () => {
    expect(createCourseVersionSchema.safeParse({ ...VALID, changelog: 'short' }).success).toBe(false)
  })

  it('accepts all 3 CHANGE_TYPES', () => {
    expect(CHANGE_TYPES).toHaveLength(3)
    for (const ct of CHANGE_TYPES) {
      expect(createCourseVersionSchema.safeParse({ ...VALID, change_type: ct }).success).toBe(true)
    }
  })
})

describe('promoteCourseVersionSchema', () => {
  it('rejects approved without approved_by', () => {
    const r = promoteCourseVersionSchema.safeParse({ target_status: 'approved' })
    expect(r.success).toBe(false)
  })

  it('accepts review without approved_by', () => {
    const r = promoteCourseVersionSchema.safeParse({ target_status: 'review' })
    expect(r.success).toBe(true)
  })

  it('accepts approved with approved_by uuid', () => {
    const r = promoteCourseVersionSchema.safeParse({
      target_status: 'approved',
      approved_by: '11111111-1111-1111-1111-111111111111',
    })
    expect(r.success).toBe(true)
  })
})

describe('nextVersion', () => {
  it('bumps major correctly', () => {
    expect(nextVersion('1.2.3', 'major')).toBe('2.0.0')
  })
  it('bumps minor correctly', () => {
    expect(nextVersion('1.2.3', 'minor')).toBe('1.3.0')
  })
  it('bumps patch correctly', () => {
    expect(nextVersion('1.2.3', 'patch')).toBe('1.2.4')
  })
})
