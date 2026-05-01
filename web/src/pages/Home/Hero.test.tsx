import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Hero } from './Hero'

it('renders headline', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText(/belajar lebih/i)).toBeInTheDocument()
})

it('renders "Mulai Belajar" CTA button', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText(/mulai belajar/i)).toBeInTheDocument()
})

it('renders "Lihat Kelas Batch" secondary link', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText(/lihat kelas batch/i)).toBeInTheDocument()
})
