import { describe, it, expect } from 'vitest'
import { createApprovalSchema, decisionSchema } from '../approval'
import { createBranchSchema } from '../branch'
import { createPartnerSchema } from '../partner'
import { createMouSchema } from '../mou'
import { createProjectSchema } from '../project'

const UUID = '11111111-1111-1111-1111-111111111111'

describe('createApprovalSchema', () => {
  const VALID = {
    type: 'create_batch' as const,
    title: 'New batch',
    description: 'desc',
    approver_id: UUID,
    entity_type: 'coursebatch',
    entity_id: 'b-1',
  }

  it('accepts valid input', () => {
    expect(createApprovalSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects empty title', () => {
    expect(createApprovalSchema.safeParse({ ...VALID, title: '' }).success).toBe(false)
  })

  it('rejects invalid type', () => {
    expect(createApprovalSchema.safeParse({ ...VALID, type: 'bogus' }).success).toBe(false)
  })

  it('rejects non-uuid approver_id', () => {
    expect(createApprovalSchema.safeParse({ ...VALID, approver_id: 'abc' }).success).toBe(false)
  })

  it('decisionSchema accepts empty reason', () => {
    expect(decisionSchema.safeParse({}).success).toBe(true)
  })

  it('decisionSchema rejects oversized reason', () => {
    expect(decisionSchema.safeParse({ reason: 'x'.repeat(2001) }).success).toBe(false)
  })
})

describe('createBranchSchema', () => {
  const VALID = {
    code: 'JKT',
    name: 'Jakarta HQ',
    address: 'Jl. Sudirman',
    city: 'Jakarta',
    province: 'DKI',
    phone: '021-1234',
    email: 'jkt@vernon.id',
    is_active: true,
  }

  it('accepts valid input', () => {
    expect(createBranchSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects empty code', () => {
    expect(createBranchSchema.safeParse({ ...VALID, code: '' }).success).toBe(false)
  })

  it('rejects bad email', () => {
    expect(createBranchSchema.safeParse({ ...VALID, email: 'not-email' }).success).toBe(false)
  })

  it('accepts empty email', () => {
    expect(createBranchSchema.safeParse({ ...VALID, email: '' }).success).toBe(true)
  })

  it('defaults is_active to true when omitted', () => {
    const r = createBranchSchema.safeParse({ code: 'BDG', name: 'Bandung' })
    expect(r.success).toBe(true)
    if (r.success) expect(r.data.is_active).toBe(true)
  })
})

describe('createPartnerSchema', () => {
  const VALID = {
    name: 'PT Acme',
    type: 'corporate' as const,
    status: 'active' as const,
    contact_name: 'Budi',
    contact_email: 'budi@acme.id',
    contact_phone: '08123',
    address: '',
    notes: '',
  }

  it('accepts valid input', () => {
    expect(createPartnerSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects empty name', () => {
    expect(createPartnerSchema.safeParse({ ...VALID, name: '' }).success).toBe(false)
  })

  it('rejects invalid type', () => {
    expect(createPartnerSchema.safeParse({ ...VALID, type: 'alien' }).success).toBe(false)
  })

  it('accepts empty contact_email', () => {
    expect(createPartnerSchema.safeParse({ ...VALID, contact_email: '' }).success).toBe(true)
  })
})

describe('createMouSchema', () => {
  const VALID = {
    title: 'MOU 2026',
    description: '',
    start_date: '2026-01-01',
    end_date: '2026-12-31',
    document_url: 'https://example.com/doc.pdf',
    status: 'active' as const,
  }

  it('accepts valid input', () => {
    expect(createMouSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects bad date format', () => {
    expect(createMouSchema.safeParse({ ...VALID, start_date: '01-01-2026' }).success).toBe(false)
  })

  it('rejects end_date before start_date', () => {
    expect(
      createMouSchema.safeParse({ ...VALID, start_date: '2026-12-01', end_date: '2026-01-01' })
        .success,
    ).toBe(false)
  })

  it('accepts empty document_url', () => {
    expect(createMouSchema.safeParse({ ...VALID, document_url: '' }).success).toBe(true)
  })
})

describe('createProjectSchema', () => {
  const VALID = {
    code: 'P-001',
    name: 'Hackathon 2026',
    description: '',
    status: 'planning' as const,
    start_date: '2026-06-01',
    end_date: '2026-06-30',
    partner_id: UUID,
    budget: 1000000,
    earning: 0,
  }

  it('accepts valid input', () => {
    expect(createProjectSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects empty name', () => {
    expect(createProjectSchema.safeParse({ ...VALID, name: '' }).success).toBe(false)
  })

  it('rejects negative budget', () => {
    expect(createProjectSchema.safeParse({ ...VALID, budget: -1 }).success).toBe(false)
  })

  it('coerces string budget to number', () => {
    const r = createProjectSchema.safeParse({ ...VALID, budget: '500000' as unknown as number })
    expect(r.success).toBe(true)
    if (r.success) expect(r.data.budget).toBe(500000)
  })

  it('rejects end_date before start_date', () => {
    expect(
      createProjectSchema.safeParse({ ...VALID, start_date: '2026-07-01', end_date: '2026-06-01' })
        .success,
    ).toBe(false)
  })
})
