import { render, screen } from '@testing-library/react'
import { B2BSection } from './B2BSection'

it('renders headline', () => {
  render(<B2BSection />)
  expect(screen.getByText(/tingkatkan kualitas/i)).toBeInTheDocument()
})

it('renders Akses Talent Pool card', () => {
  render(<B2BSection />)
  expect(screen.getByText('Akses Talent Pool')).toBeInTheDocument()
})
