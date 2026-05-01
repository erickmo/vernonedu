import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { About } from './About'

it('renders About heading', () => {
  render(<BrowserRouter><About /></BrowserRouter>)
  expect(screen.getByText(/tentang vernonedu/i)).toBeInTheDocument()
})

it('renders contact section', () => {
  render(<BrowserRouter><About /></BrowserRouter>)
  expect(screen.getByText(/kontak/i)).toBeInTheDocument()
})
