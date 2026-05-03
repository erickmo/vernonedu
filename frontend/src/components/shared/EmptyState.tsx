import React from 'react'
import { motion } from 'framer-motion'
import { fadeInUp } from '@/lib/utils/motion'
import { Inbox } from 'lucide-react'

interface EmptyStateProps {
  title: string
  description: string
  icon?: React.ElementType
  illustration?: React.ReactNode
  action?: {
    label: string
    onClick: () => void
  }
}

export default function EmptyState({ title, description, icon: Icon = Inbox, illustration, action }: EmptyStateProps) {
  return (
    <motion.div
      className="flex flex-col items-center justify-center py-16 px-8 text-center"
      variants={fadeInUp}
      initial="hidden"
      animate="visible"
    >
      {illustration ? (
        <div className="mb-6">
          {illustration}
        </div>
      ) : (
        <div className="w-16 h-16 rounded-full bg-neutral-100 flex items-center justify-center mb-4">
          <Icon className="w-8 h-8 text-neutral-400" />
        </div>
      )}
      <h3 className="text-base font-semibold text-neutral-700 mb-1">{title}</h3>
      <p className="text-sm text-neutral-500 max-w-xs">{description}</p>
      {action && (
        <motion.button
          onClick={action.onClick}
          className="mt-4 px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors"
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          {action.label}
        </motion.button>
      )}
    </motion.div>
  )
}
