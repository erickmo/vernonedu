import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { BlogCard } from './BlogCard'
import { BLOG_POSTS } from '../../data/blog-posts'

it('renders blog title and category', () => {
  render(<BrowserRouter><BlogCard post={BLOG_POSTS[0]} /></BrowserRouter>)
  expect(screen.getByText(/5 Skill/i)).toBeInTheDocument()
  expect(screen.getByText('Tips Karier')).toBeInTheDocument()
})

it('renders read time', () => {
  render(<BrowserRouter><BlogCard post={BLOG_POSTS[0]} /></BrowserRouter>)
  expect(screen.getByText(/5 min/i)).toBeInTheDocument()
})
