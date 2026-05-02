import { format, parseISO } from 'date-fns'
import { id } from 'date-fns/locale'

const IDR_FORMATTER = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
  maximumFractionDigits: 0,
})

export function formatCurrency(amount: number, currency = 'IDR'): string {
  if (currency === 'IDR') {
    return IDR_FORMATTER.format(amount)
  }
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(amount)
}

function toDate(date: string | number | Date): Date {
  if (date instanceof Date) return date
  if (typeof date === 'number') return new Date(date < 1e12 ? date * 1000 : date)
  if (/^\d+$/.test(date)) {
    const n = Number(date)
    return new Date(n < 1e12 ? n * 1000 : n)
  }
  return parseISO(date)
}

export function formatDate(date: string | number | Date): string {
  return format(toDate(date), 'dd MMM yyyy', { locale: id })
}

export function formatDateTime(date: string | number | Date): string {
  return format(toDate(date), 'dd MMM yyyy HH:mm', { locale: id })
}

export function formatPercent(value: number): string {
  return `${value.toFixed(1)}%`
}

export function truncate(str: string, length: number): string {
  if (str.length <= length) return str
  return `${str.slice(0, length)}...`
}
