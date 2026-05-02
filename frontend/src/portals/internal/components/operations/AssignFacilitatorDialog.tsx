import { useState, useEffect } from 'react'
import * as Dialog from '@radix-ui/react-dialog'
import { toast } from 'sonner'
import { useAssignFacilitator } from '@/lib/api/coursebatch'
import { assignFacilitatorSchema } from '@/schemas/coursebatch'

interface Props {
  open: boolean
  batchId: string
  initialFacilitatorId?: string
  onClose: () => void
}

export default function AssignFacilitatorDialog({
  open,
  batchId,
  initialFacilitatorId,
  onClose,
}: Props) {
  const [value, setValue] = useState(initialFacilitatorId ?? '')
  const [error, setError] = useState<string | null>(null)
  const assign = useAssignFacilitator(batchId)

  useEffect(() => {
    if (open) {
      setValue(initialFacilitatorId ?? '')
      setError(null)
    }
  }, [open, initialFacilitatorId])

  async function onSave() {
    const parsed = assignFacilitatorSchema.safeParse({ facilitator_id: value })
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? 'Invalid facilitator id')
      return
    }
    try {
      await assign.mutateAsync(parsed.data)
      toast.success('Facilitator assigned')
      onClose()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to assign facilitator')
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={(o) => !o && onClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
        <Dialog.Content className="fixed left-1/2 top-1/2 z-50 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-xl shadow-xl p-6">
          <Dialog.Title className="text-base font-semibold text-neutral-900">
            Assign Facilitator
          </Dialog.Title>
          <Dialog.Description className="mt-1 text-sm text-neutral-500">
            Enter the facilitator user UUID to assign.
          </Dialog.Description>

          <div className="mt-4">
            <label className="block text-xs font-medium text-neutral-600 mb-1">
              Facilitator User ID (UUID)
            </label>
            <input
              type="text"
              value={value}
              onChange={(e) => setValue(e.target.value)}
              placeholder="00000000-0000-0000-0000-000000000000"
              className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg font-mono"
            />
            {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
          </div>

          <div className="mt-6 flex items-center justify-end gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-neutral-700 bg-neutral-100 rounded-lg hover:bg-neutral-200 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={onSave}
              disabled={assign.isPending}
              className="px-4 py-2 text-sm font-medium text-white rounded-lg bg-brand-600 hover:bg-brand-700 transition-colors disabled:opacity-60"
            >
              {assign.isPending ? 'Saving…' : 'Save'}
            </button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
