/**
 * DepartmentForm Component
 * Reusable form component for creating and editing departments with leader selection
 */

import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Department, Staff } from '@/types/department'
import {
  departmentFormSchema,
  DepartmentFormValues,
} from '@/schemas/department'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Label from '@/components/ui/Label'
import StaffSelectDropdown from './StaffSelectDropdown'

interface DepartmentFormProps {
  staff: Staff[]
  initialData?: Department
  loading?: boolean
  onSubmit: (values: DepartmentFormValues) => Promise<void>
  onCancel?: () => void
}

export default function DepartmentForm({
  staff,
  initialData,
  loading = false,
  onSubmit,
  onCancel,
}: DepartmentFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting, isValid },
    reset,
  } = useForm<DepartmentFormValues>({
    resolver: zodResolver(departmentFormSchema),
    mode: 'onChange',
    defaultValues: {
      name: initialData?.name || '',
      description: initialData?.description || '',
      leaderId: initialData?.leaderId || '',
    },
  })

  // Pre-fill form when initialData changes
  useEffect(() => {
    if (initialData) {
      reset({
        name: initialData.name,
        description: initialData.description || '',
        leaderId: initialData.leaderId,
      })
    }
  }, [initialData, reset])

  const isLoading = loading || isSubmitting

  const handleFormSubmit = async (values: DepartmentFormValues) => {
    try {
      await onSubmit(values)
    } catch (error) {
      // Error handling is done in parent component
      console.error('Form submission error:', error)
    }
  }

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
      {/* Name Field */}
      <div className="space-y-1.5">
        <Label required>Nama Departemen *</Label>
        <Input
          {...register('name')}
          placeholder="Masukkan nama departemen"
          error={!!errors.name}
          disabled={isLoading}
        />
        {errors.name && (
          <p className="text-xs text-red-600">{errors.name.message}</p>
        )}
      </div>

      {/* Description Field */}
      <div className="space-y-1.5">
        <Label>Deskripsi</Label>
        <Textarea
          {...register('description')}
          placeholder="Masukkan deskripsi departemen (opsional)"
          rows={4}
          error={!!errors.description}
          disabled={isLoading}
        />
        <p className="text-xs text-neutral-500">
          Opsional, maksimal 500 karakter
        </p>
        {errors.description && (
          <p className="text-xs text-red-600">{errors.description.message}</p>
        )}
      </div>

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
          <p className="text-xs text-red-600">{errors.leaderId.message}</p>
        )}
      </div>

      {/* Form Actions */}
      <div className="flex gap-3 pt-4">
        <Button
          type="submit"
          variant="primary"
          disabled={!isValid || isLoading}
          loading={isLoading}
        >
          {isLoading
            ? 'Menyimpan...'
            : initialData
              ? 'Perbarui'
              : 'Buat'}
        </Button>
        {onCancel && (
          <Button
            type="button"
            variant="secondary"
            onClick={onCancel}
            disabled={isLoading}
          >
            Batal
          </Button>
        )}
      </div>
    </form>
  )
}
