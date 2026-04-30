import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { FeaturesSection } from './FeaturesSection'

it('renders Talent Pool feature', () => {
  render(<BrowserRouter><FeaturesSection /></BrowserRouter>)
  expect(screen.getAllByText(/talent pool alumni/i).length).toBeGreaterThan(0)
})

it('renders BNSP & SKKNI feature', () => {
  render(<BrowserRouter><FeaturesSection /></BrowserRouter>)
  expect(screen.getByText(/BNSP & SKKNI/i)).toBeInTheDocument()
})

it('renders B2B partnership card', () => {
  render(<BrowserRouter><FeaturesSection /></BrowserRouter>)
  expect(screen.getByText(/hubungi tim partnership/i)).toBeInTheDocument()
})
