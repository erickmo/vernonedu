import { describe, it, expect } from 'vitest'
import {
  createCertificateTemplateSchema,
  CERT_TYPES,
} from '../certificatetemplate'

describe('createCertificateTemplateSchema', () => {
  it('accepts valid input with JSON object string', () => {
    const r = createCertificateTemplateSchema.safeParse({
      name: 'Default Participant',
      type: 'participant',
      template_data: '{"title":"Certificate of Participant"}',
    })
    expect(r.success).toBe(true)
  })

  it('rejects empty name', () => {
    const r = createCertificateTemplateSchema.safeParse({
      name: '',
      type: 'participant',
      template_data: '{}',
    })
    expect(r.success).toBe(false)
  })

  it('rejects unknown type', () => {
    const r = createCertificateTemplateSchema.safeParse({
      name: 'X',
      type: 'unknown',
      template_data: '{}',
    })
    expect(r.success).toBe(false)
  })

  it('rejects invalid JSON in template_data', () => {
    const r = createCertificateTemplateSchema.safeParse({
      name: 'X',
      type: 'participant',
      template_data: '{not json',
    })
    expect(r.success).toBe(false)
  })

  it('rejects JSON array in template_data', () => {
    const r = createCertificateTemplateSchema.safeParse({
      name: 'X',
      type: 'participant',
      template_data: '[1,2,3]',
    })
    expect(r.success).toBe(false)
  })

  it('rejects JSON primitive in template_data', () => {
    const r = createCertificateTemplateSchema.safeParse({
      name: 'X',
      type: 'participant',
      template_data: '"hello"',
    })
    expect(r.success).toBe(false)
  })

  it('accepts both competency and participant types', () => {
    for (const t of CERT_TYPES) {
      const r = createCertificateTemplateSchema.safeParse({
        name: 'X',
        type: t,
        template_data: '{}',
      })
      expect(r.success).toBe(true)
    }
  })

  it('exports CERT_TYPES with both expected values', () => {
    expect(CERT_TYPES).toEqual(['participant', 'competency'])
  })
})
