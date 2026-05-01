import { render, screen } from '@testing-library/react'
import { PartnerList } from './PartnerList'

it('renders partner heading', () => {
  render(<PartnerList />)
  expect(screen.getByText(/dipercaya oleh/i)).toBeInTheDocument()
})

it('renders at least one partner chip', () => {
  render(<PartnerList />)
  expect(screen.getByText('Universitas Indonesia')).toBeInTheDocument()
})
