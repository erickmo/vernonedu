import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import type { CalendarEvent } from '@/types/calendar.types'
import { EventDot } from '../EventDot'
import { CalendarCell } from '../CalendarCell'
import { CalendarGrid } from '../CalendarGrid'

const makeEvent = (overrides: Partial<CalendarEvent> = {}): CalendarEvent => ({
  id: '1',
  title: 'Test Event',
  description: null,
  event_type: 'staff_meeting',
  start_at: '2026-05-07T09:00:00Z',
  end_at: '2026-05-07T10:00:00Z',
  is_all_day: false,
  recurrence_rule: null,
  location: null,
  source_domain: null,
  source_id: null,
  created_by: 'user-1',
  created_at: '2026-05-01T00:00:00Z',
  ...overrides,
})

describe('EventDot', () => {
  it('renders a span with title as tooltip', () => {
    render(<EventDot event={makeEvent({ title: 'Rapat Mingguan' })} />)
    expect(screen.getByTitle('Rapat Mingguan')).toBeTruthy()
  })

  it('uses correct color for class_session', () => {
    render(<EventDot event={makeEvent({ event_type: 'class_session' })} />)
    const style = screen.getByTitle('Test Event').getAttribute('style') ?? ''
    // jsdom converts hex to rgb: #3b82f6 → rgb(59, 130, 246)
    expect(style).toMatch(/background-color:\s*(#3b82f6|rgb\(59,\s*130,\s*246\))/i)
  })

  it('uses correct color for payment_due', () => {
    render(<EventDot event={makeEvent({ event_type: 'payment_due' })} />)
    const style = screen.getByTitle('Test Event').getAttribute('style') ?? ''
    // jsdom converts hex to rgb: #ef4444 → rgb(239, 68, 68)
    expect(style).toMatch(/background-color:\s*(#ef4444|rgb\(239,\s*68,\s*68\))/i)
  })
})

describe('CalendarCell', () => {
  it('renders day number', () => {
    render(<CalendarCell day={7} events={[]} isToday={false} isSelected={false} onClick={() => {}} />)
    expect(screen.getByText('7')).toBeTruthy()
  })

  it('renders dots for events', () => {
    const events = [makeEvent({ title: 'E1' }), makeEvent({ id: '2', title: 'E2' })]
    render(<CalendarCell day={7} events={events} isToday={false} isSelected={false} onClick={() => {}} />)
    expect(screen.getByTitle('E1')).toBeTruthy()
    expect(screen.getByTitle('E2')).toBeTruthy()
  })

  it('shows +N more when events exceed 5', () => {
    const events = Array.from({ length: 7 }, (_, i) => makeEvent({ id: String(i), title: `E${i}` }))
    render(<CalendarCell day={1} events={events} isToday={false} isSelected={false} onClick={() => {}} />)
    expect(screen.getByText('+2')).toBeTruthy()
  })

  it('calls onClick when clicked', () => {
    let clicked = false
    render(<CalendarCell day={5} events={[]} isToday={false} isSelected={false} onClick={() => { clicked = true }} />)
    fireEvent.click(screen.getByText('5'))
    expect(clicked).toBe(true)
  })
})

describe('CalendarGrid', () => {
  it('renders 7 day labels', () => {
    render(<CalendarGrid year={2026} month={4} events={[]} selectedDate={null} onDayClick={() => {}} />)
    expect(screen.getByText('Min')).toBeTruthy()
    expect(screen.getByText('Sab')).toBeTruthy()
  })

  it('renders correct number of days for May 2026 (31 days)', () => {
    render(<CalendarGrid year={2026} month={4} events={[]} selectedDate={null} onDayClick={() => {}} />)
    expect(screen.getByText('31')).toBeTruthy()
    expect(screen.queryByText('32')).toBeNull()
  })

  it('passes events to the correct day cell', () => {
    const event = makeEvent({ title: 'Kelas Python', start_at: '2026-05-07T09:00:00Z', end_at: '2026-05-07T10:00:00Z' })
    render(<CalendarGrid year={2026} month={4} events={[event]} selectedDate={null} onDayClick={() => {}} />)
    expect(screen.getByTitle('Kelas Python')).toBeTruthy()
  })

  it('calls onDayClick with correct date', () => {
    let clicked: Date | null = null
    render(<CalendarGrid year={2026} month={4} events={[]} selectedDate={null} onDayClick={d => { clicked = d }} />)
    fireEvent.click(screen.getByText('15'))
    expect(clicked).not.toBeNull()
    expect((clicked as unknown as Date).getDate()).toBe(15)
  })
})
