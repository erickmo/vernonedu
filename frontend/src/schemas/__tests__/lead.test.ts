import { describe, it, expect } from 'vitest'
import { createLeadSchema, updateLeadSchema, addCrmLogSchema } from '../lead'

const VALID_CREATE = {
  name: 'John Doe',
  email: 'john@example.com',
  phone: '08123456789',
  interest: 'Web Dev',
  source: 'website',
  notes: 'Interested in evening class',
}

describe('createLeadSchema', () => {
  it('accepts valid input', () => {
    const r = createLeadSchema.safeParse(VALID_CREATE)
    expect(r.success).toBe(true)
  })

  it('rejects empty name', () => {
    const r = createLeadSchema.safeParse({ ...VALID_CREATE, name: '' })
    expect(r.success).toBe(false)
  })

  it('rejects invalid email format', () => {
    const r = createLeadSchema.safeParse({ ...VALID_CREATE, email: 'not-an-email' })
    expect(r.success).toBe(false)
  })

  it('accepts empty email', () => {
    const r = createLeadSchema.safeParse({ ...VALID_CREATE, email: '' })
    expect(r.success).toBe(true)
  })

  it('defaults optional fields to empty string', () => {
    const r = createLeadSchema.safeParse({ name: 'Jane' })
    expect(r.success).toBe(true)
    if (r.success) {
      expect(r.data.email).toBe('')
      expect(r.data.notes).toBe('')
    }
  })
})

describe('updateLeadSchema', () => {
  it('accepts valid status', () => {
    const r = updateLeadSchema.safeParse({ ...VALID_CREATE, status: 'contacted' })
    expect(r.success).toBe(true)
  })

  it('rejects invalid status', () => {
    const r = updateLeadSchema.safeParse({ ...VALID_CREATE, status: 'invalid_status' })
    expect(r.success).toBe(false)
  })
})

describe('addCrmLogSchema', () => {
  it('accepts valid log', () => {
    const r = addCrmLogSchema.safeParse({
      contacted_by_id: '11111111-1111-1111-1111-111111111111',
      contact_method: 'call',
      response: 'Spoke with lead, interested',
    })
    expect(r.success).toBe(true)
  })

  it('rejects empty response', () => {
    const r = addCrmLogSchema.safeParse({
      contacted_by_id: '11111111-1111-1111-1111-111111111111',
      contact_method: 'call',
      response: '',
    })
    expect(r.success).toBe(false)
  })

  it('rejects non-UUID contacted_by_id', () => {
    const r = addCrmLogSchema.safeParse({
      contacted_by_id: 'not-a-uuid',
      contact_method: 'call',
      response: 'note',
    })
    expect(r.success).toBe(false)
  })

  it('rejects invalid contact_method', () => {
    const r = addCrmLogSchema.safeParse({
      contacted_by_id: '11111111-1111-1111-1111-111111111111',
      contact_method: 'pigeon',
      response: 'note',
    })
    expect(r.success).toBe(false)
  })
})
