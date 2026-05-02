import { describe, it, expect } from 'vitest'
import {
  createMarketingPostSchema,
  updateMarketingPostSchema,
  submitPostUrlSchema,
} from '../marketingpost'
import { createReferralPartnerSchema, updateReferralPartnerSchema } from '../referralpartner'
import { createMarketingPrSchema } from '../marketingpr'

describe('createMarketingPostSchema', () => {
  const VALID = {
    platforms: ['instagram'],
    scheduled_at: '2026-05-01T10:00:00Z',
    content_type: 'image',
    caption: 'hello',
  }

  it('accepts valid input', () => {
    expect(createMarketingPostSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects empty platforms', () => {
    expect(createMarketingPostSchema.safeParse({ ...VALID, platforms: [] }).success).toBe(false)
  })

  it('rejects invalid platform', () => {
    expect(
      createMarketingPostSchema.safeParse({ ...VALID, platforms: ['myspace'] }).success,
    ).toBe(false)
  })

  it('rejects invalid content_type', () => {
    expect(createMarketingPostSchema.safeParse({ ...VALID, content_type: 'foo' }).success).toBe(
      false,
    )
  })

  it('update accepts status', () => {
    expect(
      updateMarketingPostSchema.safeParse({ ...VALID, status: 'scheduled' }).success,
    ).toBe(true)
  })
})

describe('submitPostUrlSchema', () => {
  it('accepts valid url', () => {
    expect(submitPostUrlSchema.safeParse({ post_url: 'https://ig.com/p/1' }).success).toBe(true)
  })

  it('rejects empty', () => {
    expect(submitPostUrlSchema.safeParse({ post_url: '' }).success).toBe(false)
  })
})

describe('createReferralPartnerSchema', () => {
  const VALID = {
    name: 'Alpha',
    referral_code: 'ALPHA10',
    commission_type: 'percent' as const,
    commission_value: 10,
  }

  it('accepts valid', () => {
    expect(createReferralPartnerSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects negative commission', () => {
    expect(
      createReferralPartnerSchema.safeParse({ ...VALID, commission_value: -1 }).success,
    ).toBe(false)
  })

  it('rejects invalid commission_type', () => {
    expect(
      createReferralPartnerSchema.safeParse({ ...VALID, commission_type: 'foo' }).success,
    ).toBe(false)
  })

  it('rejects invalid email', () => {
    expect(
      createReferralPartnerSchema.safeParse({ ...VALID, contact_email: 'bad' }).success,
    ).toBe(false)
  })

  it('update accepts is_active', () => {
    expect(
      updateReferralPartnerSchema.safeParse({
        name: 'Alpha',
        commission_type: 'fixed',
        commission_value: 100000,
        is_active: false,
      }).success,
    ).toBe(true)
  })
})

describe('createMarketingPrSchema', () => {
  it('accepts valid', () => {
    const r = createMarketingPrSchema.safeParse({
      title: 'Interview at Detik',
      type: 'interview',
      scheduled_at: '2026-05-01T10:00:00Z',
    })
    expect(r.success).toBe(true)
  })

  it('rejects invalid type', () => {
    expect(
      createMarketingPrSchema.safeParse({
        title: 'x',
        type: 'foo',
        scheduled_at: '2026-05-01',
      }).success,
    ).toBe(false)
  })
})
