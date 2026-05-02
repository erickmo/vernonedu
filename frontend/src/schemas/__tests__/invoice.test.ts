import { describe, it, expect } from 'vitest'
import {
  createInvoiceSchema,
  invoiceStatusSchema,
  invoiceLineItemSchema,
} from '@/schemas/invoice'

const STUDENT_UUID = '11111111-1111-1111-1111-111111111111'
const BATCH_UUID = '22222222-2222-2222-2222-222222222222'

describe('createInvoiceSchema', () => {
  it('accepts valid input with student_id', () => {
    const result = createInvoiceSchema.safeParse({
      student_id: STUDENT_UUID,
      amount: 1500000,
      due_date: '2026-06-01',
    })
    expect(result.success).toBe(true)
  })

  it('accepts valid input with course_batch_id only', () => {
    const result = createInvoiceSchema.safeParse({
      course_batch_id: BATCH_UUID,
      amount: 0,
      due_date: '2026-06-01',
    })
    expect(result.success).toBe(true)
  })

  it('rejects when both student_id and course_batch_id missing', () => {
    const result = createInvoiceSchema.safeParse({
      amount: 100,
      due_date: '2026-06-01',
    })
    expect(result.success).toBe(false)
  })

  it('rejects negative amount', () => {
    const result = createInvoiceSchema.safeParse({
      student_id: STUDENT_UUID,
      amount: -1,
      due_date: '2026-06-01',
    })
    expect(result.success).toBe(false)
  })

  it('rejects bad date format', () => {
    const result = createInvoiceSchema.safeParse({
      student_id: STUDENT_UUID,
      amount: 100,
      due_date: '01/06/2026',
    })
    expect(result.success).toBe(false)
  })

  it('rejects non-UUID student_id', () => {
    const result = createInvoiceSchema.safeParse({
      student_id: 'not-uuid',
      amount: 100,
      due_date: '2026-06-01',
    })
    expect(result.success).toBe(false)
  })
})

describe('invoiceStatusSchema', () => {
  it('accepts known statuses', () => {
    expect(invoiceStatusSchema.safeParse('paid').success).toBe(true)
    expect(invoiceStatusSchema.safeParse('cancelled').success).toBe(true)
  })

  it('rejects unknown status', () => {
    expect(invoiceStatusSchema.safeParse('refunded').success).toBe(false)
  })
})

describe('invoiceLineItemSchema', () => {
  it('accepts valid line item', () => {
    const r = invoiceLineItemSchema.safeParse({
      description: 'Tuition',
      quantity: 1,
      unit_price: 500000,
      total: 500000,
    })
    expect(r.success).toBe(true)
  })

  it('rejects zero quantity', () => {
    const r = invoiceLineItemSchema.safeParse({
      description: 'Tuition',
      quantity: 0,
      unit_price: 100,
      total: 0,
    })
    expect(r.success).toBe(false)
  })
})
