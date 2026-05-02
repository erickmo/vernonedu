// Lightweight CSV export helper. Pure functions — easy to unit test.
// Used by finance report pages to provide client-side download buttons.

const COMMA = ','
const NEWLINE = '\n'
const QUOTE = '"'

function needsQuote(value: string): boolean {
  return value.includes(COMMA) || value.includes(NEWLINE) || value.includes(QUOTE)
}

export function escapeCsvCell(value: unknown): string {
  if (value === null || value === undefined) return ''
  const str = String(value)
  if (!needsQuote(str)) return str
  return `${QUOTE}${str.replace(/"/g, '""')}${QUOTE}`
}

export function rowsToCsv(headers: string[], rows: Array<Array<unknown>>): string {
  const headerLine = headers.map(escapeCsvCell).join(COMMA)
  const bodyLines = rows.map((row) => row.map(escapeCsvCell).join(COMMA))
  return [headerLine, ...bodyLines].join(NEWLINE)
}

export function downloadCsv(filename: string, csv: string): void {
  if (typeof window === 'undefined' || typeof document === 'undefined') return
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename.endsWith('.csv') ? filename : `${filename}.csv`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

export function exportRowsAsCsv(
  filename: string,
  headers: string[],
  rows: Array<Array<unknown>>,
): void {
  downloadCsv(filename, rowsToCsv(headers, rows))
}
