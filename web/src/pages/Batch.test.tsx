import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Batch } from './Batch'
import { BATCHES } from '../data/batches'

it('renders page title', () => {
  render(<BrowserRouter><Batch /></BrowserRouter>)
  expect(screen.getByText(/semua kelas batch/i)).toBeInTheDocument()
})

it('renders all batches by default', () => {
  render(<BrowserRouter><Batch /></BrowserRouter>)
  BATCHES.forEach(b => {
    expect(screen.getByText(new RegExp(b.name, 'i'))).toBeInTheDocument()
  })
})
