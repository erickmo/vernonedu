import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { RoomList } from '@/pages/Operations/LocationListPage'

describe('RoomList', () => {
  it('renders empty state when no rooms', () => {
    render(<RoomList rooms={[]} />)
    expect(screen.getByText('Belum ada ruangan')).toBeTruthy()
  })

  it('renders room names and capacity', () => {
    const rooms = [
      { id: '1', name: 'R.101', capacity: 20 },
      { id: '2', name: 'R.102', capacity: 30 },
    ]
    render(<RoomList rooms={rooms} />)
    expect(screen.getByText('R.101')).toBeTruthy()
    expect(screen.getByText('R.102')).toBeTruthy()
    expect(screen.getByText('20 orang')).toBeTruthy()
    expect(screen.getByText('30 orang')).toBeTruthy()
  })

  it('does not render capacity for zero-capacity rooms', () => {
    const rooms = [
      { id: '1', name: 'R.101', capacity: 0 },
    ]
    render(<RoomList rooms={rooms} />)
    expect(screen.getByText('R.101')).toBeTruthy()
    expect(screen.queryByText('0 orang')).toBeNull()
  })

  it('displays multiple rooms with mixed capacities', () => {
    const rooms = [
      { id: '1', name: 'Ruang Kelas A', capacity: 25 },
      { id: '2', name: 'Ruang Praktik', capacity: 0 },
      { id: '3', name: 'Ruang Meeting', capacity: 15 },
    ]
    render(<RoomList rooms={rooms} />)
    expect(screen.getByText('Ruang Kelas A')).toBeTruthy()
    expect(screen.getByText('Ruang Praktik')).toBeTruthy()
    expect(screen.getByText('Ruang Meeting')).toBeTruthy()
    expect(screen.getByText('25 orang')).toBeTruthy()
    expect(screen.getByText('15 orang')).toBeTruthy()
    expect(screen.queryByText('0 orang')).toBeNull()
  })
})
