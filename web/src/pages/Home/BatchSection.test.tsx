import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { BatchSection } from './BatchSection'

it('renders section title', () => {
  render(<BrowserRouter><BatchSection /></BrowserRouter>)
  expect(screen.getByText(/kelas batch/i)).toBeInTheDocument()
})

it('renders first 3 batches', () => {
  render(<BrowserRouter><BatchSection /></BrowserRouter>)
  expect(screen.getByText(/English for Professionals/i)).toBeInTheDocument()
  expect(screen.getByText(/UI\/UX Design/i)).toBeInTheDocument()
  expect(screen.getByText(/Python for Data/i)).toBeInTheDocument()
})
