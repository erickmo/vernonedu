import { render, screen } from '@testing-library/react'
import { CourseTicker } from './CourseTicker'

it('renders at least one course item', () => {
  render(<CourseTicker />)
  expect(screen.getAllByText(/bahasa inggris/i).length).toBeGreaterThan(0)
})
