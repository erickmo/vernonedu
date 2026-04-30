import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { BatchCard } from './BatchCard'
import { BATCHES } from '../../data/batches'

const batch = BATCHES[0] // english-batch-12

it('renders batch name and number', () => {
  render(<BrowserRouter><BatchCard batch={batch} /></BrowserRouter>)
  expect(screen.getByText(/English for Professionals/i)).toBeInTheDocument()
  expect(screen.getByText(/Batch 12/i)).toBeInTheDocument()
})

it('renders start date', () => {
  render(<BrowserRouter><BatchCard batch={batch} /></BrowserRouter>)
  expect(screen.getByText(/15 Mei 2025/i)).toBeInTheDocument()
})

it('renders seats left when not null', () => {
  render(<BrowserRouter><BatchCard batch={batch} /></BrowserRouter>)
  expect(screen.getByText(/12 kursi tersisa/i)).toBeInTheDocument()
})

it('shows "Masih tersedia" when seatsLeft is null', () => {
  const nullBatch = BATCHES[2] // python-batch-5 seatsLeft: null
  render(<BrowserRouter><BatchCard batch={nullBatch} /></BrowserRouter>)
  expect(screen.getByText(/masih tersedia/i)).toBeInTheDocument()
})
