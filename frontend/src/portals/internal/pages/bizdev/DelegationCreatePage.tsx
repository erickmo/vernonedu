import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import { createDelegationSchema, type CreateDelegationInput } from '@/schemas/delegation'
import { useCreateDelegation } from '@/lib/api/delegation'
import { DELEGATION_TYPES, DELEGATION_PRIORITIES } from '@/types/delegation'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Delegations', to: '/internal/delegations' },
  { label: 'New' },
]

export default function DelegationCreatePage() {
  const navigate = useNavigate()
  const create = useCreateDelegation()

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<CreateDelegationInput>({
    resolver: zodResolver(createDelegationSchema),
    defaultValues: {
      title: '', type: 'task', description: '',
      requested_by_id: '', requested_by_name: '',
      assigned_to_id: '', assigned_to_name: '',
      priority: 'medium', notes: '',
    },
  })

  async function onSubmit(values: CreateDelegationInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Delegation created')
      navigate('/internal/delegations')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="New Delegation" subtitle="Assign a task or request">
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Title" required error={errors.title?.message}>
          <Input {...register('title')} />
        </FormField>
        <div className="grid grid-cols-2 gap-3">
          <FormField label="Type" required error={errors.type?.message}>
            <Select {...register('type')}>
              {DELEGATION_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
            </Select>
          </FormField>
          <FormField label="Priority" error={errors.priority?.message}>
            <Select {...register('priority')}>
              {DELEGATION_PRIORITIES.map((p) => <option key={p} value={p}>{p}</option>)}
            </Select>
          </FormField>
        </div>
        <FormField label="Description" error={errors.description?.message}>
          <Textarea {...register('description')} rows={3} />
        </FormField>
        <div className="grid grid-cols-2 gap-3">
          <FormField label="Requested By ID" required error={errors.requested_by_id?.message}>
            <Input {...register('requested_by_id')} />
          </FormField>
          <FormField label="Requested By Name" required error={errors.requested_by_name?.message}>
            <Input {...register('requested_by_name')} />
          </FormField>
          <FormField label="Assigned To ID" required error={errors.assigned_to_id?.message}>
            <Input {...register('assigned_to_id')} />
          </FormField>
          <FormField label="Assigned To Name" required error={errors.assigned_to_name?.message}>
            <Input {...register('assigned_to_name')} />
          </FormField>
          <FormField label="Assigned To Role" error={errors.assigned_to_role?.message}>
            <Input {...register('assigned_to_role')} />
          </FormField>
          <FormField label="Due Date" error={errors.due_date?.message}>
            <Input type="date" {...register('due_date')} />
          </FormField>
        </div>
        <FormField label="Notes" error={errors.notes?.message}>
          <Textarea {...register('notes')} rows={3} />
        </FormField>
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/delegations')}>Cancel</Button>
          <Button type="submit" loading={isSubmitting}>Save</Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
