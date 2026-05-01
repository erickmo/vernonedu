import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { TestimonialSection } from './TestimonialSection'

it('renders featured testimonial author', () => {
  render(<BrowserRouter><TestimonialSection /></BrowserRouter>)
  expect(screen.getByText('Rina Kusuma')).toBeInTheDocument()
})

it('renders all 3 testimonials', () => {
  render(<BrowserRouter><TestimonialSection /></BrowserRouter>)
  expect(screen.getByText('Dr. Hendra Wijaya')).toBeInTheDocument()
  expect(screen.getByText('Ayu Permata')).toBeInTheDocument()
})
