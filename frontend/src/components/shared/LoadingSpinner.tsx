import { cn } from '@/lib/utils/cn'
import { motion } from 'framer-motion'
import { fadeIn } from '@/lib/utils/motion'

type SpinnerSize = 'sm' | 'md' | 'lg'

interface LoadingSpinnerProps {
  size?: SpinnerSize
  className?: string
}

const DIMENSIONS: Record<SpinnerSize, number> = { sm: 16, md: 32, lg: 48 }

export default function LoadingSpinner({ size = 'md', className }: LoadingSpinnerProps) {
  return (
    <motion.div
      className={cn('flex items-center justify-center', className)}
      initial="hidden"
      animate="visible"
      exit="exit"
      variants={fadeIn}
    >
      <div
        className="animate-spin rounded-full border-2 border-brand-100 border-t-brand-600"
        style={{ width: DIMENSIONS[size], height: DIMENSIONS[size] }}
      />
    </motion.div>
  )
}
