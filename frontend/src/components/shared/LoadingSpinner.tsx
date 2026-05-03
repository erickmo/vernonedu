import { cn } from '@/lib/utils/cn'
import { motion } from 'framer-motion'
import { fadeIn } from '@/lib/utils/motion'

type SpinnerSize = 'sm' | 'md' | 'lg'

const SIZE_CLASS: Record<SpinnerSize, string> = {
  sm: 'w-4 h-4 border-[2px]',
  md: 'w-8 h-8 border-[2px]',
  lg: 'w-12 h-12 border-[3px]',
}

interface LoadingSpinnerProps {
  size?: SpinnerSize
  className?: string
}

export default function LoadingSpinner({ size = 'md', className }: LoadingSpinnerProps) {
  const borderClasses = {
    sm: 'border-[2px]',
    md: 'border-[2px]',
    lg: 'border-[3px]',
  }

  return (
    <motion.div
      className={cn('flex items-center justify-center', className)}
      initial="hidden"
      animate="visible"
      exit="exit"
      variants={fadeIn}
    >
      <div
        className={cn(
          'rounded-full border-[#f8f0fd] border-t-[#7a4e90]',
          'animate-spin',
          borderClasses[size]
        )}
        style={{
          width: size === 'sm' ? '16px' : size === 'md' ? '32px' : '48px',
          height: size === 'sm' ? '16px' : size === 'md' ? '32px' : '48px',
        }}
      >
        <style jsx>{`
          @keyframes spin {
            to {
              transform: rotate(360deg);
            }
          }
          .animate-spin {
            animation: spin 1s linear infinite;
          }
        `}</style>
      </div>
    </motion.div>
  )
}
