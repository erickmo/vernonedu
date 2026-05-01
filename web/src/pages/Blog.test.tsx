import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Blog } from './Blog'
import { BLOG_POSTS } from '../data/blog-posts'

it('renders Blog heading', () => {
  render(<BrowserRouter><Blog /></BrowserRouter>)
  expect(screen.getByText(/blog/i)).toBeInTheDocument()
})

it('renders all blog post titles', () => {
  render(<BrowserRouter><Blog /></BrowserRouter>)
  BLOG_POSTS.forEach(post => {
    expect(screen.getByText(post.title)).toBeInTheDocument()
  })
})
