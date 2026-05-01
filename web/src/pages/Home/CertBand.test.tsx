import { render, screen } from '@testing-library/react'
import { CertBand } from './CertBand'

it('renders BNSP', () => {
  render(<CertBand />)
  expect(screen.getByText(/BNSP/i)).toBeInTheDocument()
})

it('renders SKKNI', () => {
  render(<CertBand />)
  expect(screen.getByText(/SKKNI/i)).toBeInTheDocument()
})
