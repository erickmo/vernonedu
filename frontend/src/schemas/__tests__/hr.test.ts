import { describe, it, expect } from 'vitest'
import { createUserSchema, updateUserSchema } from '../user'
import { facilitatorLevelSchema, upsertFacilitatorLevelsSchema } from '../facilitatorlevel'
import { updateCommissionConfigSchema } from '../commissionconfig'
import { updateTalentPoolStatusSchema } from '../talentpool'
import { professionSchema } from '../profession'
import { createItemSchema, updateItemSchema } from '../item'
import { createCanvasSchema } from '../canvas'
import { createDesignThinkingSchema } from '../designthinking'

describe('createUserSchema', () => {
  it('accepts valid input', () => {
    const r = createUserSchema.safeParse({
      name: 'Alice',
      email: 'a@b.com',
      password: 'secret123',
      roles: ['facilitator'],
    })
    expect(r.success).toBe(true)
  })

  it('rejects invalid email', () => {
    const r = createUserSchema.safeParse({
      name: 'A',
      email: 'not-email',
      password: 'secret123',
      roles: ['facilitator'],
    })
    expect(r.success).toBe(false)
  })

  it('rejects empty roles', () => {
    const r = createUserSchema.safeParse({
      name: 'A',
      email: 'a@b.com',
      password: 'secret123',
      roles: [],
    })
    expect(r.success).toBe(false)
  })

  it('rejects short password', () => {
    const r = createUserSchema.safeParse({
      name: 'A',
      email: 'a@b.com',
      password: '123',
      roles: ['student'],
    })
    expect(r.success).toBe(false)
  })
})

describe('updateUserSchema', () => {
  it('accepts name', () => {
    expect(updateUserSchema.safeParse({ name: 'New Name' }).success).toBe(true)
  })
  it('rejects empty name', () => {
    expect(updateUserSchema.safeParse({ name: '' }).success).toBe(false)
  })
})

describe('facilitatorLevelSchema', () => {
  it('accepts valid level', () => {
    const r = facilitatorLevelSchema.safeParse({
      level: 1,
      name: 'Junior',
      fee_per_session: 100000,
    })
    expect(r.success).toBe(true)
  })

  it('rejects negative fee', () => {
    const r = facilitatorLevelSchema.safeParse({
      level: 1,
      name: 'Junior',
      fee_per_session: -1,
    })
    expect(r.success).toBe(false)
  })

  it('rejects empty levels array', () => {
    expect(upsertFacilitatorLevelsSchema.safeParse({ levels: [] }).success).toBe(false)
  })
})

describe('updateCommissionConfigSchema', () => {
  it('accepts valid config', () => {
    const r = updateCommissionConfigSchema.safeParse({
      op_leader_pct: 5,
      op_leader_basis: 'profit',
      dept_leader_pct: 10,
      dept_leader_basis: 'profit',
      course_creator_pct: 15,
      course_creator_basis: 'revenue',
    })
    expect(r.success).toBe(true)
  })

  it('rejects pct above 100', () => {
    const r = updateCommissionConfigSchema.safeParse({
      op_leader_pct: 101,
      op_leader_basis: 'profit',
      dept_leader_pct: 10,
      dept_leader_basis: 'profit',
      course_creator_pct: 15,
      course_creator_basis: 'revenue',
    })
    expect(r.success).toBe(false)
  })

  it('rejects invalid basis', () => {
    const r = updateCommissionConfigSchema.safeParse({
      op_leader_pct: 5,
      op_leader_basis: 'wrong',
      dept_leader_pct: 10,
      dept_leader_basis: 'profit',
      course_creator_pct: 15,
      course_creator_basis: 'revenue',
    })
    expect(r.success).toBe(false)
  })
})

describe('updateTalentPoolStatusSchema', () => {
  it('accepts valid stage', () => {
    expect(updateTalentPoolStatusSchema.safeParse({ status: 'internship' }).success).toBe(true)
  })

  it('rejects unknown stage', () => {
    expect(updateTalentPoolStatusSchema.safeParse({ status: 'foo' }).success).toBe(false)
  })

  it('accepts placement record for placed', () => {
    const r = updateTalentPoolStatusSchema.safeParse({
      status: 'placed',
      placement: { company_name: 'Acme', position: 'Dev', notes: '' },
    })
    expect(r.success).toBe(true)
  })
})

describe('professionSchema', () => {
  it('accepts valid input', () => {
    expect(professionSchema.safeParse({ name: 'Backend Dev', description: '' }).success).toBe(true)
  })
  it('rejects empty name', () => {
    expect(professionSchema.safeParse({ name: '', description: '' }).success).toBe(false)
  })
})

describe('createItemSchema', () => {
  it('accepts valid item', () => {
    const r = createItemSchema.safeParse({
      business_id: '11111111-1111-1111-1111-111111111111',
      canvas_type: 'bmc',
      section_id: 'value_propositions',
      text: 'Hi',
      note: '',
    })
    expect(r.success).toBe(true)
  })

  it('rejects non-uuid business_id', () => {
    const r = createItemSchema.safeParse({
      business_id: 'not-uuid',
      canvas_type: 'bmc',
      section_id: 's',
      text: 'Hi',
      note: '',
    })
    expect(r.success).toBe(false)
  })

  it('updateItemSchema rejects empty text', () => {
    expect(updateItemSchema.safeParse({ text: '', note: '' }).success).toBe(false)
  })
})

describe('canvas + designthinking', () => {
  it('createCanvasSchema accepts name', () => {
    expect(createCanvasSchema.safeParse({ name: 'My Canvas' }).success).toBe(true)
  })
  it('createCanvasSchema rejects empty name', () => {
    expect(createCanvasSchema.safeParse({ name: '' }).success).toBe(false)
  })
  it('createDesignThinkingSchema accepts name', () => {
    expect(createDesignThinkingSchema.safeParse({ name: 'DT Project' }).success).toBe(true)
  })
})
