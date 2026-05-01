/**
 * AssignLeaderDialog Component
 * Modal dialog for assigning a new department leader
 */

import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as Dialog from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { Staff } from '@/types/department'
import {
  assignLeaderSchema,
  AssignLeaderValues,
} from '@/schemas/department'
import Button from '@/components/ui/Button'
import Label from '@/components/ui/Label'
import StaffSelectDropdown from './StaffSelectDropdown'

interface AssignLeaderDialogProps {
  open: boolean
  staff: Staff[]
  currentLeaderId?: string
  loading?: boolean
  onSubmit: (values: AssignLeaderValues) => Promise<void>
  onOpenChange: (open: boolean) => void
}

export default function AssignLeaderDialog({
  open,
  staff,
  currentLeaderId,
  loading = false,
  onSubmit,
  onOpenChange,
}: AssignLeaderDialogProps) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting, isValid },
    reset,
  } = useForm<AssignLeaderValues>({
    resolver: zodResolver(assignLeaderSchema),
    mode: 'onChange',
    defaultValues: {
      leaderId: currentLeaderId || '',
    },
  })

  // Reset form when dialog opens/closes
  useEffect(() => {
    if (open) {
      reset({
        leaderId: currentLeaderId || '',
      })
    }
  }, [open, currentLeaderId, reset])

  const isLoading = loading || isSubmitting

  const handleFormSubmit = async (values: AssignLeaderValues) => {
    try {
      await onSubmit(values)
      // Close dialog on success
      onOpenChange(false)
    } catch (error) {
      // Error handling is done in parent component via toast
      console.error('Form submission error:', error)
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0" />
        <Dialog.Content className="fixed left-1/2 top-1/2 z-50 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-xl shadow-xl p-6 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95">
          <div className="flex items-center justify-between mb-4">
            <div>
              <Dialog.Title className="text-lg font-semibold text-neutral-900">
                Ubah Kepala Departemen
              </Dialog.Title>
              <Dialog.Description className="mt-1 text-sm text-neutral-500">
                Pilih kepala departemen baru untuk departemen ini
              </Dialog.Description>
            </div>
            <Dialog.Close asChild>
              <button
                className="p-1 hover:bg-neutral-100 rounded-lg transition-colors"
                disabled={isLoading}
              >
                <X className="w-5 h-5 text-neutral-400" />
              </button>
            </Dialog.Close>
          </div>

          {/* Form */}
          <form
            onSubmit={handleSubmit(handleFormSubmit)}
            className="space-y-4"
          >
            {/* Leader Selection Field */}
            <div className="space-y-1.5">
              <Label required>Kepala Departemen *</Label>
              <StaffSelectDropdown
                {...register('leaderId')}
                staff={staff}
                placeholder="Pilih kepala departemen"
                error={!!errors.leaderId}
                disabled={isLoading}
              />
              {errors.leaderId && (
                <p className="text-xs text-red-600">
                  {errors.leaderId.message}
                </p>
              )}
            </div>

            {/* Form Actions */}
            <div className="flex items-center justify-end gap-3 pt-4 border-t border-neutral-200">
              <button
                type="button"
                onClick={() => onOpenChange(false)}
                disabled={isLoading}
                className="px-4 py-2 text-sm font-medium text-neutral-700 bg-neutral-100 rounded-lg hover:bg-neutral-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Batal
              </button>
              <Button
                type="submit"
                variant="primary"
                disabled={!isValid || isLoading}
                loading={isLoading}
              >
                {isLoading ? 'Menyimpan...' : 'Simpan'}
              </Button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
