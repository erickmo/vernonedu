import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Footer } from './Footer'

it('renders brand name', () => {
  render(<BrowserRouter><Footer /></BrowserRouter>)
  expect(screen.getAllByText(/vernonedu/i).length).toBeGreaterThan(0)
})

it('renders Talent Pool link', () => {
  render(<BrowserRouter><Footer /></BrowserRouter>)
  expect(screen.getAllByRole('link', { name: /talent pool/i }).length).toBeGreaterThan(0)
})

it('renders Verifikasi Sertifikat link', () => {
  render(<BrowserRouter><Footer /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /verifikasi sertifikat/i })).toBeInTheDocument()
})
