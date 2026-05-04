import styles from './FormPageTemplate.module.css'

interface FormColumnProps {
  children: React.ReactNode
  style?: React.CSSProperties
}

export function FormColumn({ children, style }: FormColumnProps) {
  return <div className={styles.column} style={style}>{children}</div>
}
