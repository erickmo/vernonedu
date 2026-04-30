import { BATCHES } from './batches'
import { PARTNERS, COURSE_TICKER_ITEMS } from './partners'
import { TESTIMONIALS } from './testimonials'
import { FEATURES } from './features'
import { FAQS } from './faqs'
import { BLOG_POSTS } from './blog-posts'

it('BATCHES has exactly one featured per color variant', () => {
  const variants = BATCHES.map(b => b.colorVariant)
  expect(new Set(variants).size).toBe(BATCHES.length)
})

it('TESTIMONIALS has exactly one featured', () => {
  expect(TESTIMONIALS.filter(t => t.featured).length).toBe(1)
})

it('BLOG_POSTS has exactly one featured', () => {
  expect(BLOG_POSTS.filter(p => p.featured).length).toBe(1)
})

it('all blog post slugs are unique', () => {
  const slugs = BLOG_POSTS.map(p => p.slug)
  expect(new Set(slugs).size).toBe(slugs.length)
})

it('PARTNERS is non-empty', () => {
  expect(PARTNERS.length).toBeGreaterThan(0)
})

it('COURSE_TICKER_ITEMS is non-empty', () => {
  expect(COURSE_TICKER_ITEMS.length).toBeGreaterThan(0)
})

it('FEATURES has talent-pool entry', () => {
  expect(FEATURES.find(f => f.id === 'talent-pool')).toBeDefined()
})

it('FAQS has certification entry', () => {
  expect(FAQS.find(f => f.id === 'certification')).toBeDefined()
})
