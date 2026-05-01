import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Nav } from './Nav'

it('renders logo text', () => {
  render(<BrowserRouter><Nav /></BrowserRouter>)
  expect(screen.getByText('Vernon')).toBeInTheDocument()
})

it('renders Kelas Batch nav link', () => {
  render(<BrowserRouter><Nav /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /kelas batch/i })).toBeInTheDocument()
})

it('renders Blog nav link', () => {
  render(<BrowserRouter><Nav /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /blog/i })).toBeInTheDocument()
})

it('renders Daftar Sekarang CTA', () => {
  render(<BrowserRouter><Nav /></BrowserRouter>)
  expect(screen.getByText(/daftar sekarang/i)).toBeInTheDocument()
})
