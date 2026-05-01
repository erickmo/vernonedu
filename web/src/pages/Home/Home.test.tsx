import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { Home } from './index'

it('renders hero headline', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/belajar lebih/i)).toBeInTheDocument()
})

it('renders BNSP in cert band', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/terakreditasi BNSP/i)).toBeInTheDocument()
})

it('renders kelas batch section', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/English for Professionals/i)).toBeInTheDocument()
})

it('renders talent pool feature', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getAllByText(/talent pool alumni/i).length).toBeGreaterThan(0)
})

it('renders blog preview', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/5 Skill/i)).toBeInTheDocument()
})
