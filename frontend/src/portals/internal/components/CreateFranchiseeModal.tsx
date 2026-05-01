import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useCreateFranchisee } from '@/lib/api/franchise'
import FormModal from '@/components/shared/FormModal'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'

const schema = z.object({
  name: z.string().min(2, 'Name required'),
  branch_name: z.string().min(2, 'Branch name required'),
  location: z.string().min(2, 'Location required'),
  contact: z.string().min(5, 'Contact required'),
})

type FormData = z.infer<typeof schema>

interface CreateFranchiseeModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function CreateFranchiseeModal({ open, onOpenChange }: CreateFranchiseeModalProps) {
  const createFranchisee = useCreateFranchisee()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({ resolver: zodResolver(schema) })

  const onSubmit = async (data: FormData) => {
    try {
      await createFranchisee.mutateAsync(data)
      toast.success('Franchisee created')
      onOpenChange(false)
      reset()
    } catch {
      toast.error('Failed to create franchisee')
    }
  }

  return (
    <FormModal
      open={open}
      onOpenChange={onOpenChange}
      title="Add Franchisee"
      onSubmit={handleSubmit(onSubmit)}
      loading={createFranchisee.isPending}
      submitLabel="Create Franchisee"
    >
      <FormField label="Name" error={errors.name?.message} required>
        <Input {...register('name')} error={!!errors.name} />
      </FormField>
      <FormField label="Branch Name" error={errors.branch_name?.message} required>
        <Input {...register('branch_name')} error={!!errors.branch_name} />
      </FormField>
      <FormField label="Location" error={errors.location?.message} required>
        <Input {...register('location')} error={!!errors.location} />
      </FormField>
      <FormField label="Contact" error={errors.contact?.message} required>
        <Input {...register('contact')} error={!!errors.contact} />
      </FormField>
    </FormModal>
  )
}
