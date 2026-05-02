import { describe, it, expect } from 'vitest'
import { createCoaSchema, updateCoaSchema } from '@/schemas/coa'
import {
  createFinanceAccountSchema,
  updateFinanceAccountSchema,
} from '@/schemas/financeaccount'
import { createTransactionSchema } from '@/schemas/transaction'
import { createPayableSchema, payPayableSchema } from '@/schemas/payable'

const UUID_A = '00000000-0000-4000-8000-000000000001'
const UUID_B = '00000000-0000-4000-8000-000000000002'
const UUID_C = '00000000-0000-4000-8000-000000000003'

describe('createCoaSchema', () => {
  it('accepts valid CoA payload', () => {
    const r = createCoaSchema.safeParse({
      code: '1100',
      name: 'Kas',
      type: 'asset',
    })
    expect(r.success).toBe(true)
  })

  it('rejects too-short code', () => {
    const r = createCoaSchema.safeParse({ code: '11', name: 'Kas', type: 'asset' })
    expect(r.success).toBe(false)
  })

  it('rejects invalid type', () => {
    const r = createCoaSchema.safeParse({ code: '1100', name: 'Kas', type: 'foo' })
    expect(r.success).toBe(false)
  })

  it('rejects non-uuid parent_id', () => {
    const r = createCoaSchema.safeParse({
      code: '1100',
      name: 'Kas',
      type: 'asset',
      parent_id: 'not-a-uuid',
    })
    expect(r.success).toBe(false)
  })
})

describe('updateCoaSchema', () => {
  it('requires is_active boolean', () => {
    const r = updateCoaSchema.safeParse({ name: 'Kas Besar', is_active: true })
    expect(r.success).toBe(true)
  })

  it('rejects empty name', () => {
    const r = updateCoaSchema.safeParse({ name: '', is_active: true })
    expect(r.success).toBe(false)
  })
})

describe('createFinanceAccountSchema', () => {
  it('defaults type to asset', () => {
    const r = createFinanceAccountSchema.safeParse({
      code: '1101',
      name: 'BCA Operasional',
    })
    expect(r.success).toBe(true)
    if (r.success) expect(r.data.type).toBe('asset')
  })

  it('accepts kind=bank', () => {
    const r = createFinanceAccountSchema.safeParse({
      code: '1101',
      name: 'BCA',
      kind: 'bank',
    })
    expect(r.success).toBe(true)
  })

  it('rejects invalid kind', () => {
    const r = createFinanceAccountSchema.safeParse({
      code: '1101',
      name: 'BCA',
      kind: 'crypto',
    })
    expect(r.success).toBe(false)
  })
})

describe('updateFinanceAccountSchema', () => {
  it('passes with valid input', () => {
    const r = updateFinanceAccountSchema.safeParse({
      name: 'BCA Cabang Utama',
      is_active: false,
    })
    expect(r.success).toBe(true)
  })
})

describe('createTransactionSchema', () => {
  it('accepts a valid double-entry transaction', () => {
    const r = createTransactionSchema.safeParse({
      description: 'Setoran kas',
      account_debit_id: UUID_A,
      account_credit_id: UUID_B,
      amount: 500_000,
      branch_id: UUID_C,
    })
    expect(r.success).toBe(true)
  })

  it('rejects when debit equals credit', () => {
    const r = createTransactionSchema.safeParse({
      description: 'invalid',
      account_debit_id: UUID_A,
      account_credit_id: UUID_A,
      amount: 100,
      branch_id: UUID_C,
    })
    expect(r.success).toBe(false)
  })

  it('rejects zero amount', () => {
    const r = createTransactionSchema.safeParse({
      description: 'invalid',
      account_debit_id: UUID_A,
      account_credit_id: UUID_B,
      amount: 0,
      branch_id: UUID_C,
    })
    expect(r.success).toBe(false)
  })

  it('rejects invalid attachment url', () => {
    const r = createTransactionSchema.safeParse({
      description: 'ok',
      account_debit_id: UUID_A,
      account_credit_id: UUID_B,
      amount: 100,
      branch_id: UUID_C,
      attachment_url: 'not-a-url',
    })
    expect(r.success).toBe(false)
  })
})

describe('createPayableSchema', () => {
  it('accepts valid payable', () => {
    const r = createPayableSchema.safeParse({
      type: 'facilitator_fee',
      recipient_id: UUID_A,
      recipient_name: 'Pak Budi',
      amount: 500_000,
    })
    expect(r.success).toBe(true)
  })

  it('rejects invalid type', () => {
    const r = createPayableSchema.safeParse({
      type: 'random_thing',
      recipient_id: UUID_A,
      recipient_name: 'X',
      amount: 100,
    })
    expect(r.success).toBe(false)
  })

  it('rejects negative amount', () => {
    const r = createPayableSchema.safeParse({
      type: 'vendor',
      recipient_id: UUID_A,
      recipient_name: 'X',
      amount: -1,
    })
    expect(r.success).toBe(false)
  })
})

describe('payPayableSchema', () => {
  it('accepts empty body', () => {
    const r = payPayableSchema.safeParse({})
    expect(r.success).toBe(true)
  })

  it('accepts proof + account_code', () => {
    const r = payPayableSchema.safeParse({
      payment_proof: 'https://files/x.jpg',
      account_code: '1101',
    })
    expect(r.success).toBe(true)
  })
})
