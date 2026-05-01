import { render, screen } from '@testing-library/react'
import { FaqSection } from './FaqSection'

it('renders all 5 FAQ questions', () => {
  render(<FaqSection />)
  expect(screen.getByText(/apa itu kelas batch/i)).toBeInTheDocument()
  expect(screen.getByText(/talent pool/i)).toBeInTheDocument()
  expect(screen.getByText(/sertifikasi apa/i)).toBeInTheDocument()
})
