import { describe, it, expect } from 'vitest'
import { updateBMCSchema } from '../bmc'
import {
  createObjectiveSchema,
  createKeyResultSchema,
  updateKeyResultProgressSchema,
} from '../okr'
import { createInvestmentSchema, updateInvestmentSchema } from '../investment'
import {
  createDelegationSchema,
  updateDelegationSchema,
  transitionDelegationSchema,
} from '../delegation'

const NINE_COMPONENTS = [
  { key: 'key_partners', label: 'Key Partners', content: 'a' },
  { key: 'key_activities', label: 'Key Activities', content: '' },
  { key: 'key_resources', label: 'Key Resources', content: '' },
  { key: 'value_propositions', label: 'Value Propositions', content: '' },
  { key: 'customer_relationships', label: 'Customer Relationships', content: '' },
  { key: 'channels', label: 'Channels', content: '' },
  { key: 'customer_segments', label: 'Customer Segments', content: '' },
  { key: 'cost_structure', label: 'Cost Structure', content: '' },
  { key: 'revenue_streams', label: 'Revenue Streams', content: '' },
] as const

describe('updateBMCSchema', () => {
  it('accepts 9 components', () => {
    const r = updateBMCSchema.safeParse({ components: NINE_COMPONENTS })
    expect(r.success).toBe(true)
  })

  it('rejects fewer than 9 components', () => {
    const r = updateBMCSchema.safeParse({ components: NINE_COMPONENTS.slice(0, 8) })
    expect(r.success).toBe(false)
  })

  it('rejects invalid component key', () => {
    const bad = NINE_COMPONENTS.map((c, i) =>
      i === 0 ? { ...c, key: 'invalid' } : c,
    )
    const r = updateBMCSchema.safeParse({ components: bad })
    expect(r.success).toBe(false)
  })
})

describe('createObjectiveSchema', () => {
  const VALID = {
    title: 'Grow revenue',
    owner_id: 'user-1',
    owner_name: 'Alice',
    period: 'Q1 2026',
    level: 'company' as const,
    status: 'draft' as const,
  }
  it('accepts valid input', () => {
    expect(createObjectiveSchema.safeParse(VALID).success).toBe(true)
  })
  it('rejects empty title', () => {
    expect(createObjectiveSchema.safeParse({ ...VALID, title: '' }).success).toBe(false)
  })
  it('rejects unknown level', () => {
    expect(
      createObjectiveSchema.safeParse({ ...VALID, level: 'galactic' }).success,
    ).toBe(false)
  })
})

describe('createKeyResultSchema', () => {
  it('accepts valid', () => {
    const r = createKeyResultSchema.safeParse({
      objective_id: 'obj-1', title: 'Sign 10 MOUs', target: 10, current: 0, unit: 'MOU',
    })
    expect(r.success).toBe(true)
  })
  it('rejects zero target', () => {
    expect(
      createKeyResultSchema.safeParse({
        objective_id: 'obj-1', title: 'X', target: 0, current: 0,
      }).success,
    ).toBe(false)
  })
})

describe('updateKeyResultProgressSchema', () => {
  it('rejects negative current', () => {
    expect(updateKeyResultProgressSchema.safeParse({ current: -1 }).success).toBe(false)
  })
})

describe('createInvestmentSchema', () => {
  const VALID = {
    title: 'New equipment',
    category: 'Equipment',
    proposed_by: 'CEO',
    amount: 50000000,
    expected_roi: 25,
    status: 'proposed' as const,
    notes: '',
  }
  it('accepts valid input', () => {
    expect(createInvestmentSchema.safeParse(VALID).success).toBe(true)
  })
  it('rejects negative amount', () => {
    expect(createInvestmentSchema.safeParse({ ...VALID, amount: -1 }).success).toBe(false)
  })
  it('rejects negative ROI', () => {
    expect(
      createInvestmentSchema.safeParse({ ...VALID, expected_roi: -5 }).success,
    ).toBe(false)
  })
  it('updateInvestmentSchema requires title', () => {
    expect(updateInvestmentSchema.safeParse({ title: '' }).success).toBe(false)
  })
})

describe('createDelegationSchema', () => {
  const VALID = {
    title: 'Build new course',
    type: 'course_request' as const,
    description: 'desc',
    requested_by_id: 'u1', requested_by_name: 'Alice',
    assigned_to_id: 'u2', assigned_to_name: 'Bob',
    priority: 'medium' as const,
    notes: '',
  }
  it('accepts valid', () => {
    expect(createDelegationSchema.safeParse(VALID).success).toBe(true)
  })
  it('rejects empty title', () => {
    expect(createDelegationSchema.safeParse({ ...VALID, title: '' }).success).toBe(false)
  })
  it('rejects invalid type', () => {
    expect(
      createDelegationSchema.safeParse({ ...VALID, type: 'nope' }).success,
    ).toBe(false)
  })
})

describe('updateDelegationSchema', () => {
  it('rejects invalid priority', () => {
    expect(
      updateDelegationSchema.safeParse({
        title: 't', description: '', priority: 'flame', notes: '',
      }).success,
    ).toBe(false)
  })
})

describe('transitionDelegationSchema', () => {
  it('accepts empty notes', () => {
    expect(transitionDelegationSchema.safeParse({}).success).toBe(true)
  })
})
