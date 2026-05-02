import { describe, it, expect } from 'vitest'
import { updateCmsPageSchema } from '../cmspage'
import { createCmsArticleSchema, updateCmsArticleSchema } from '../cmsarticle'
import { createCmsFaqSchema } from '../cmsfaq'
import { createCmsTestimonialSchema } from '../cmstestimonial'
import { uploadCmsMediaSchema } from '../cmsmedia'

describe('updateCmsPageSchema', () => {
  it('accepts valid title', () => {
    const r = updateCmsPageSchema.safeParse({ title: 'Home' })
    expect(r.success).toBe(true)
  })

  it('rejects empty title', () => {
    const r = updateCmsPageSchema.safeParse({ title: '' })
    expect(r.success).toBe(false)
  })
})

describe('createCmsArticleSchema', () => {
  const VALID = { title: 'How to', category: 'tips', content: 'Body', status: 'draft' }

  it('accepts valid input', () => {
    expect(createCmsArticleSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects empty content', () => {
    expect(createCmsArticleSchema.safeParse({ ...VALID, content: '' }).success).toBe(false)
  })

  it('rejects invalid status', () => {
    expect(createCmsArticleSchema.safeParse({ ...VALID, status: 'foo' }).success).toBe(false)
  })

  it('update accepts slug', () => {
    expect(updateCmsArticleSchema.safeParse({ ...VALID, slug: 'how-to' }).success).toBe(true)
  })
})

describe('createCmsFaqSchema', () => {
  it('accepts valid', () => {
    const r = createCmsFaqSchema.safeParse({ question: 'Q?', answer: 'A.' })
    expect(r.success).toBe(true)
  })

  it('rejects empty question', () => {
    expect(createCmsFaqSchema.safeParse({ question: '', answer: 'A' }).success).toBe(false)
  })

  it('defaults page_slugs to []', () => {
    const r = createCmsFaqSchema.safeParse({ question: 'Q?', answer: 'A' })
    if (r.success) expect(r.data.page_slugs).toEqual([])
  })
})

describe('createCmsTestimonialSchema', () => {
  const VALID = { student_name: 'John', quote: 'Great', rating: 5 }

  it('accepts valid', () => {
    expect(createCmsTestimonialSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects rating > 5', () => {
    expect(createCmsTestimonialSchema.safeParse({ ...VALID, rating: 6 }).success).toBe(false)
  })

  it('rejects rating < 1', () => {
    expect(createCmsTestimonialSchema.safeParse({ ...VALID, rating: 0 }).success).toBe(false)
  })
})

describe('uploadCmsMediaSchema', () => {
  it('accepts valid', () => {
    const r = uploadCmsMediaSchema.safeParse({
      url: 'https://x.com/a.png',
      file_name: 'a.png',
      file_type: 'image/png',
      file_size: 1024,
    })
    expect(r.success).toBe(true)
  })

  it('rejects empty url', () => {
    expect(
      uploadCmsMediaSchema.safeParse({
        url: '',
        file_name: 'a.png',
        file_type: 'image/png',
      }).success,
    ).toBe(false)
  })
})
