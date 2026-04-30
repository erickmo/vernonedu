import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { SectionHeader } from './SectionHeader'

it('renders eyebrow and title', () => {
  render(<BrowserRouter><SectionHeader eyebrow="Kelas Batch" title={<>Kelas <em>Terjadwal</em></>} /></BrowserRouter>)
  expect(screen.getByText('Kelas Batch')).toBeInTheDocument()
  expect(screen.getByText('Terjadwal')).toBeInTheDocument()
})

it('renders seeAll link when provided', () => {
  render(
    <BrowserRouter>
      <SectionHeader
        eyebrow="Blog"
        title="Blog"
        seeAll={{ label: 'Lihat Semua', href: '/blog' }}
      />
    </BrowserRouter>
  )
  expect(screen.getByRole('link', { name: /lihat semua/i })).toHaveAttribute('href', '/blog')
})
