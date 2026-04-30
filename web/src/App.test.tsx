import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import App from './App'

it('renders nav on home route', () => {
  render(<MemoryRouter initialEntries={['/']}><App /></MemoryRouter>)
  expect(screen.getAllByText(/vernonedu/i).length).toBeGreaterThan(0)
})

it('renders 404 on unknown route', () => {
  render(<MemoryRouter initialEntries={['/xxxxunknown']}><App /></MemoryRouter>)
  expect(screen.getByText(/404/i)).toBeInTheDocument()
})
