import { type ElementType } from 'react'
import styles from './VisuallyHidden.module.css'

interface VisuallyHiddenProps {
  children: React.ReactNode
  focusable?: boolean
  as?: ElementType
}

export function VisuallyHidden({
  children,
  focusable = false,
  as: Tag = 'span',
}: VisuallyHiddenProps) {
  return (
    <Tag className={`${styles.hidden} ${focusable ? styles.focusable : ''}`}>
      {children}
    </Tag>
  )
}
