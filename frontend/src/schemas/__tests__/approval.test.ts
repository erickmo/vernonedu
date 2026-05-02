import { describe, expect, it } from 'vitest'
import {
  REASON_MAX_LENGTH,
  REASON_MIN_LENGTH,
  decisionSchema,
  wizardDecisionSchema,
} from '../approval'

describe('decisionSchema (legacy)', () => {
  it('accepts empty reason for backwards compatibility', () => {
    const r = decisionSchema.safeParse({ reason: '' })
    expect(r.success).toBe(true)
  })
})

describe('wizardDecisionSchema', () => {
  it('rejects reason shorter than minimum length', () => {
    const r = wizardDecisionSchema.safeParse({ reason: 'no' })
    expect(r.success).toBe(false)
    if (!r.success) {
      expect(r.error.issues[0].message).toContain(String(REASON_MIN_LENGTH))
    }
  })

  it('rejects whitespace-only reason', () => {
    const r = wizardDecisionSchema.safeParse({ reason: '          ' })
    expect(r.success).toBe(false)
  })

  it('accepts a valid trimmed reason at the minimum boundary', () => {
    const r = wizardDecisionSchema.safeParse({ reason: 'a'.repeat(REASON_MIN_LENGTH) })
    expect(r.success).toBe(true)
  })

  it('rejects reason longer than maximum length', () => {
    const r = wizardDecisionSchema.safeParse({ reason: 'a'.repeat(REASON_MAX_LENGTH + 1) })
    expect(r.success).toBe(false)
  })
})
