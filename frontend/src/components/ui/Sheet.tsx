import * as RadixDialog from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import { motion } from 'framer-motion'
import { fadeIn } from '@/lib/utils/motion'

export const Sheet = RadixDialog.Root
export const SheetTrigger = RadixDialog.Trigger
export const SheetClose = RadixDialog.Close

type Side = 'left' | 'right'

interface SheetContentProps {
  children: React.ReactNode
  side?: Side
  className?: string
}

const slideVariants = {
  left: {
    hidden: { x: '-100%' },
    visible: { x: 0, transition: { type: 'tween', ease: [0.25, 0.1, 0.25, 1], duration: 0.3 } },
    exit: { x: '-100%', transition: { duration: 0.15 } },
  },
  right: {
    hidden: { x: '100%' },
    visible: { x: 0, transition: { type: 'tween', ease: [0.25, 0.1, 0.25, 1], duration: 0.3 } },
    exit: { x: '100%', transition: { duration: 0.15 } },
  },
}

export function SheetContent({ children, side = 'right', className }: SheetContentProps) {
  return (
    <RadixDialog.Portal>
      <RadixDialog.Overlay asChild>
        <motion.div
          className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm"
          variants={fadeIn}
          initial="hidden"
          animate="visible"
          exit="exit"
        />
      </RadixDialog.Overlay>
      <RadixDialog.Content asChild>
        <motion.div
          className={cn(
            'fixed inset-y-0 z-50 flex flex-col bg-white shadow-modal border-border',
            side === 'right' ? 'right-0 border-l' : 'left-0 border-r',
            'w-full max-w-md',
            className,
          )}
          variants={slideVariants[side]}
          initial="hidden"
          animate="visible"
          exit="exit"
        >
          <div className="flex items-center justify-between px-5 py-4 border-b border-border">
            <RadixDialog.Title className="text-base font-semibold text-neutral-900" />
            <RadixDialog.Close className="rounded-lg p-1.5 text-neutral-400 hover:text-neutral-600 hover:bg-neutral-100 transition-colors">
              <X className="h-4 w-4" />
            </RadixDialog.Close>
          </div>
          <div className="flex-1 overflow-y-auto p-5">{children}</div>
        </motion.div>
      </RadixDialog.Content>
    </RadixDialog.Portal>
  )
}
