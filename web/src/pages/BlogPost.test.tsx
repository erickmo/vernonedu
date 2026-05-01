import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { BlogPost } from './BlogPost'

it('renders post title for valid slug', () => {
  render(
    <MemoryRouter initialEntries={['/blog/5-skill-paling-dicari-2025']}>
      <Routes>
        <Route path="/blog/:slug" element={<BlogPost />} />
      </Routes>
    </MemoryRouter>
  )
  expect(screen.getAllByText(/5 Skill/i).length).toBeGreaterThan(0)
})

it('shows 404 message for invalid slug', () => {
  render(
    <MemoryRouter initialEntries={['/blog/tidak-ada']}>
      <Routes>
        <Route path="/blog/:slug" element={<BlogPost />} />
      </Routes>
    </MemoryRouter>
  )
  expect(screen.getByText(/artikel tidak ditemukan/i)).toBeInTheDocument()
})
