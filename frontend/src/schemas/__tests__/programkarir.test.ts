import { describe, it, expect } from 'vitest'
import { upsertInternshipConfigSchema } from '../internshipconfig'
import { upsertCharacterTestConfigSchema, TEST_TYPES } from '../charactertestconfig'
import { isProgramKarir } from '@/lib/utils/coursetype'

const VALID_INTERN = {
  partner_company_name: 'PT ABC',
  partner_company_id: '',
  position_title: 'Backend Intern',
  duration_weeks: 12,
  supervisor_name: 'Budi',
  supervisor_contact: 'budi@abc.com',
  mou_document_url: '',
  is_company_provided: false,
}

describe('upsertInternshipConfigSchema', () => {
  it('accepts valid input', () => {
    expect(upsertInternshipConfigSchema.safeParse(VALID_INTERN).success).toBe(true)
  })
  it('rejects empty partner_company_name', () => {
    expect(upsertInternshipConfigSchema.safeParse({ ...VALID_INTERN, partner_company_name: '' }).success).toBe(false)
  })
  it('rejects duration_weeks <= 0', () => {
    expect(upsertInternshipConfigSchema.safeParse({ ...VALID_INTERN, duration_weeks: 0 }).success).toBe(false)
  })
  it('accepts empty mou_document_url', () => {
    expect(upsertInternshipConfigSchema.safeParse({ ...VALID_INTERN, mou_document_url: '' }).success).toBe(true)
  })
  it('rejects invalid URL when provided', () => {
    expect(upsertInternshipConfigSchema.safeParse({ ...VALID_INTERN, mou_document_url: 'not-a-url' }).success).toBe(false)
  })
  it('accepts valid URL', () => {
    expect(upsertInternshipConfigSchema.safeParse({ ...VALID_INTERN, mou_document_url: 'https://example.com/mou.pdf' }).success).toBe(true)
  })
})

const VALID_CHAR = {
  test_type: 'DISC',
  test_provider: 'TalentMapper',
  passing_threshold: 75,
  talentpool_eligible: true,
}

describe('upsertCharacterTestConfigSchema', () => {
  it('accepts all TEST_TYPES', () => {
    expect(TEST_TYPES.length).toBeGreaterThanOrEqual(4)
    for (const t of TEST_TYPES) {
      expect(upsertCharacterTestConfigSchema.safeParse({ ...VALID_CHAR, test_type: t }).success).toBe(true)
    }
  })
  it('rejects passing_threshold < 0', () => {
    expect(upsertCharacterTestConfigSchema.safeParse({ ...VALID_CHAR, passing_threshold: -1 }).success).toBe(false)
  })
  it('rejects passing_threshold > 100', () => {
    expect(upsertCharacterTestConfigSchema.safeParse({ ...VALID_CHAR, passing_threshold: 101 }).success).toBe(false)
  })
  it('accepts boundaries 0 and 100', () => {
    expect(upsertCharacterTestConfigSchema.safeParse({ ...VALID_CHAR, passing_threshold: 0 }).success).toBe(true)
    expect(upsertCharacterTestConfigSchema.safeParse({ ...VALID_CHAR, passing_threshold: 100 }).success).toBe(true)
  })
})

describe('isProgramKarir', () => {
  it('matches "Program Karir"', () => {
    expect(isProgramKarir('Program Karir')).toBe(true)
  })
  it('case-insensitive', () => {
    expect(isProgramKarir('program karir')).toBe(true)
    expect(isProgramKarir('PROGRAM KARIR')).toBe(true)
  })
  it('rejects non-Karir types', () => {
    expect(isProgramKarir('Reguler')).toBe(false)
    expect(isProgramKarir('Privat')).toBe(false)
  })
  it('handles null/undefined/empty', () => {
    expect(isProgramKarir('')).toBe(false)
    expect(isProgramKarir(undefined)).toBe(false)
    expect(isProgramKarir(null)).toBe(false)
  })
})
