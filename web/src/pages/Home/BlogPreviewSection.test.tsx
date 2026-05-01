import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { BlogPreviewSection } from './BlogPreviewSection'

it('renders featured blog post title', () => {
  render(<BrowserRouter><BlogPreviewSection /></BrowserRouter>)
  expect(screen.getByText(/5 Skill/i)).toBeInTheDocument()
})

it('renders 3 blog posts total', () => {
  render(<BrowserRouter><BlogPreviewSection /></BrowserRouter>)
  expect(screen.getAllByText(/april 2025/i).length).toBe(3)
})
