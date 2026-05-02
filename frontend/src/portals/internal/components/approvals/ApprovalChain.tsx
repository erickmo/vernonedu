import { Check, Clock, Minus } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import type { ApprovalType } from '@/types/approval'

export interface ChainStep {
  label: string
  state: 'done' | 'current' | 'upcoming'
}

/**
 * Static chain definition derived from the VernonEdu Approval Workflows
 * matrix (see root CLAUDE.md). Multi-stage flows render as a chain so the
 * approver sees where the request is in the sequence.
 */
const APPROVAL_CHAINS: Partial<Record<ApprovalType, string[]>> = {
  revoke_certificate: ['Dept Leader', 'Education Leader', 'Director'],
  create_batch: ['Course Creator', 'Operation Leader', 'Dept Leader'],
}

const DEFAULT_CHAIN = ['Approver']

const STATE_DOT: Record<ChainStep['state'], string> = {
  done: 'bg-emerald-500 border-emerald-500 text-white',
  current: 'bg-amber-400 border-amber-400 text-white ring-4 ring-amber-100',
  upcoming: 'bg-white border-neutral-300 text-neutral-400',
}

const STATE_LABEL: Record<ChainStep['state'], string> = {
  done: 'text-neutral-700',
  current: 'text-neutral-900 font-semibold',
  upcoming: 'text-neutral-400',
}

interface ApprovalChainProps {
  type: ApprovalType
  /** Index (0-based) of the current step in the chain. */
  currentStep?: number
}

export function getChainForType(type: ApprovalType): string[] {
  return APPROVAL_CHAINS[type] ?? DEFAULT_CHAIN
}

export default function ApprovalChain({ type, currentStep = 0 }: ApprovalChainProps) {
  const chain = getChainForType(type)
  if (chain.length <= 1) return null

  return (
    <div className="flex items-center justify-between gap-2">
      {chain.map((label, idx) => {
        const state: ChainStep['state'] =
          idx < currentStep ? 'done' : idx === currentStep ? 'current' : 'upcoming'
        const Icon = state === 'done' ? Check : state === 'current' ? Clock : Minus
        return (
          <div key={`${label}-${idx}`} className="flex items-center gap-2 flex-1">
            <div className="flex flex-col items-center gap-1 flex-1 min-w-0">
              <div
                className={cn(
                  'w-8 h-8 rounded-full border-2 flex items-center justify-center shrink-0',
                  STATE_DOT[state],
                )}
              >
                <Icon className="w-4 h-4" />
              </div>
              <span className={cn('text-xs text-center truncate w-full', STATE_LABEL[state])}>
                {label}
              </span>
            </div>
            {idx < chain.length - 1 && (
              <div
                className={cn(
                  'h-0.5 flex-1 -mt-5',
                  idx < currentStep ? 'bg-emerald-400' : 'bg-neutral-200',
                )}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}
