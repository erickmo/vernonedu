import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Students } from './Students'

it('renders page heading', () => {
  render(<BrowserRouter><Students /></BrowserRouter>)
  expect(screen.getByText(/kursus untuk anda/i)).toBeInTheDocument()
})

it('renders Regular Class info', () => {
  render(<BrowserRouter><Students /></BrowserRouter>)
  expect(screen.getByText(/kelas regular/i)).toBeInTheDocument()
})

it('renders Private Class info', () => {
  render(<BrowserRouter><Students /></BrowserRouter>)
  expect(screen.getByText(/kelas private/i)).toBeInTheDocument()
})

it('renders Daftar Sekarang CTA', () => {
  render(<BrowserRouter><Students /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /daftar sekarang/i })).toBeInTheDocument()
})
