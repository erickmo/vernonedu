import { describe, expect, it } from 'vitest'
import { escapeCsvCell, rowsToCsv } from '../csv'

describe('escapeCsvCell', () => {
  it('returns empty string for null/undefined', () => {
    expect(escapeCsvCell(null)).toBe('')
    expect(escapeCsvCell(undefined)).toBe('')
  })

  it('passes through plain strings and numbers', () => {
    expect(escapeCsvCell('hello')).toBe('hello')
    expect(escapeCsvCell(42)).toBe('42')
    expect(escapeCsvCell(0)).toBe('0')
  })

  it('quotes values containing comma', () => {
    expect(escapeCsvCell('a,b')).toBe('"a,b"')
  })

  it('escapes embedded double quotes', () => {
    expect(escapeCsvCell('say "hi"')).toBe('"say ""hi"""')
  })

  it('quotes values with newline', () => {
    expect(escapeCsvCell('line1\nline2')).toBe('"line1\nline2"')
  })
})

describe('rowsToCsv', () => {
  it('builds header + body lines', () => {
    const csv = rowsToCsv(['a', 'b'], [
      [1, 2],
      [3, 4],
    ])
    expect(csv).toBe('a,b\n1,2\n3,4')
  })

  it('handles empty body', () => {
    expect(rowsToCsv(['x', 'y'], [])).toBe('x,y')
  })

  it('escapes cells inside rows', () => {
    const csv = rowsToCsv(['name', 'note'], [['ali', 'hi, there']])
    expect(csv).toBe('name,note\nali,"hi, there"')
  })
})
