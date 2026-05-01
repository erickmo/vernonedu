import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Partners } from './Partners'

it('renders page heading', () => {
  render(<BrowserRouter><Partners /></BrowserRouter>)
  expect(screen.getByText(/program kemitraan/i)).toBeInTheDocument()
})

it('renders Talent Pool benefit', () => {
  render(<BrowserRouter><Partners /></BrowserRouter>)
  expect(screen.getByText(/talent pool/i)).toBeInTheDocument()
})

it('renders contact section', () => {
  render(<BrowserRouter><Partners /></BrowserRouter>)
  expect(screen.getAllByText(/hubungi kami/i).length).toBeGreaterThan(0)
})
