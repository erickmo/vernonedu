import styles from './BatchChip.module.css'

export interface BatchSummary {
  id: string
  name: string
  status: 'active' | 'completed' | 'draft' | string
  studentCount: number
  sessionDone: number
  sessionTotal: number
}

interface Props {
  batch: BatchSummary
}

export function BatchChip({ batch }: Props) {
  const isActive = batch.status === 'active'
  const isDone = batch.status === 'completed'
  const progress = batch.sessionTotal > 0
    ? Math.round((batch.sessionDone / batch.sessionTotal) * 100)
    : 0

  return (
    <div className={`${styles.chip} ${isDone ? styles.done : ''}`}>
      <div className={styles.header}>
        <span className={`${styles.dot} ${isActive ? styles.active : styles.done}`} />
        <span className={styles.name}>{batch.name}</span>
        <span className={styles.meta}>· {batch.studentCount} siswa</span>
      </div>
      <div className={styles.progressBar}>
        <div
          className={`${styles.progressFill} ${isDone ? styles.done : ''}`}
          style={{ width: `${progress}%` }}
        />
      </div>
      <div className={styles.progressLabel}>
        {isDone ? 'Selesai' : `${batch.sessionDone}/${batch.sessionTotal} sesi · ${progress}%`}
      </div>
    </div>
  )
}
