import { describe, it, expect } from 'vitest'
import {
  issueCertificateSchema,
  revokeCertificateSchema,
  CERTIFICATE_TYPES,
} from '../certificate'

describe('issueCertificateSchema', () => {
  const valid = {
    template_id: 't-1',
    student_id: 's-1',
    batch_id: 'b-1',
    course_id: 'c-1',
    type: 'participant' as const,
    verification_base_url: 'https://verify.vernon.edu',
    notes: 'Issued after final session',
  }

  it('accepts valid issue input', () => {
    const r = issueCertificateSchema.safeParse(valid)
    expect(r.success).toBe(true)
  })

  it('accepts both certificate types', () => {
    expect(CERTIFICATE_TYPES).toEqual(['participant', 'competency'])
    const r = issueCertificateSchema.safeParse({ ...valid, type: 'competency' })
    expect(r.success).toBe(true)
  })

  it('rejects empty template_id', () => {
    const r = issueCertificateSchema.safeParse({ ...valid, template_id: '' })
    expect(r.success).toBe(false)
  })

  it('rejects empty student_id', () => {
    const r = issueCertificateSchema.safeParse({ ...valid, student_id: '' })
    expect(r.success).toBe(false)
  })

  it('rejects unknown type', () => {
    const r = issueCertificateSchema.safeParse({ ...valid, type: 'gold' as any })
    expect(r.success).toBe(false)
  })

  it('rejects malformed verification_base_url', () => {
    const r = issueCertificateSchema.safeParse({ ...valid, verification_base_url: 'not-a-url' })
    expect(r.success).toBe(false)
  })

  it('allows omitting optional notes and verification_base_url', () => {
    const r = issueCertificateSchema.safeParse({
      template_id: 't', student_id: 's', batch_id: 'b', course_id: 'c', type: 'participant',
    })
    expect(r.success).toBe(true)
  })
})

describe('revokeCertificateSchema', () => {
  it('accepts a valid reason', () => {
    const r = revokeCertificateSchema.safeParse({ reason: 'Issued in error' })
    expect(r.success).toBe(true)
  })

  it('rejects too-short reason', () => {
    const r = revokeCertificateSchema.safeParse({ reason: 'no' })
    expect(r.success).toBe(false)
  })

  it('rejects empty reason', () => {
    const r = revokeCertificateSchema.safeParse({ reason: '' })
    expect(r.success).toBe(false)
  })
})
