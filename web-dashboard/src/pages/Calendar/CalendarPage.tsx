import { useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import styles from './CalendarPage.module.css'

const DAYS = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
const MONTHS = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
]

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate()
}

function getFirstDayOfMonth(year: number, month: number) {
  return new Date(year, month, 1).getDay()
}

export default function CalendarPage() {
  const today = new Date()
  const [viewYear, setViewYear] = useState(today.getFullYear())
  const [viewMonth, setViewMonth] = useState(today.getMonth())

  const daysInMonth = getDaysInMonth(viewYear, viewMonth)
  const firstDay = getFirstDayOfMonth(viewYear, viewMonth)
  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ]

  const prevMonth = () => {
    if (viewMonth === 0) { setViewMonth(11); setViewYear(y => y - 1) }
    else setViewMonth(m => m - 1)
  }

  const nextMonth = () => {
    if (viewMonth === 11) { setViewMonth(0); setViewYear(y => y + 1) }
    else setViewMonth(m => m + 1)
  }

  const isToday = (day: number) =>
    day === today.getDate() && viewMonth === today.getMonth() && viewYear === today.getFullYear()

  return (
    <div className={styles.page}>
      <div className={styles.card}>
        <div className={styles.header}>
          <button className={styles.navBtn} onClick={prevMonth}>
            <ChevronLeft size={18} />
          </button>
          <h2 className={styles.title}>{MONTHS[viewMonth]} {viewYear}</h2>
          <button className={styles.navBtn} onClick={nextMonth}>
            <ChevronRight size={18} />
          </button>
        </div>

        <div className={styles.grid}>
          {DAYS.map(d => (
            <div key={d} className={styles.dayLabel}>{d}</div>
          ))}
          {cells.map((day, i) => (
            <div
              key={i}
              className={day ? (isToday(day) ? styles.cellToday : styles.cell) : styles.cellEmpty}
            >
              {day ?? ''}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
