import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Hero } from './Hero'

it('renders headline', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText(/belajar lebih/i)).toBeInTheDocument()
})

it('renders audience chooser options', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText(/siswa \/ pelajar/i)).toBeInTheDocument()
  expect(screen.getAllByText(/mitra institusi/i).length).toBeGreaterThan(0)
})

it('renders stat: 12K+ Siswa Aktif', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText('12K+')).toBeInTheDocument()
  expect(screen.getByText(/siswa aktif/i)).toBeInTheDocument()
})
