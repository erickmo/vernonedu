import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import { createProjectSchema, type CreateProjectInput } from '@/schemas/project'
import { PROJECT_STATUSES } from '@/types/project'
import { useCreateProject } from '@/lib/api/project'
import { usePartners } from '@/lib/api/partner'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Operations', to: '/internal/operations' },
  { label: 'Projects', to: '/internal/projects' },
  { label: 'New Project' },
]

export default function ProjectCreatePage() {
  const navigate = useNavigate()
  const create = useCreateProject()
  const { data: partnerList } = usePartners({ limit: 100 })

  const {
    register, handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateProjectInput>({
    resolver: zodResolver(createProjectSchema),
    defaultValues: {
      code: '', name: '', description: '',
      status: 'planning',
      start_date: '', end_date: '',
      partner_id: null, branch_id: null,
      budget: 0, earning: 0,
    },
  })

  async function onSubmit(values: CreateProjectInput) {
    try {
      const payload = {
        ...values,
        partner_id: values.partner_id || null,
        branch_id: values.branch_id || null,
      }
      const res = await create.mutateAsync(payload)
      toast.success('Project created')
      const id = (res as any)?.data?.id ?? (res as any)?.id
      navigate(id ? `/internal/projects/${id}` : '/internal/projects')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create project')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Add Project" subtitle="Create a new project">
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Code" required error={errors.code?.message}>
            <Input {...register('code')} placeholder="P-001" />
          </FormField>
          <FormField label="Status" error={errors.status?.message}>
            <Select {...register('status')}>
              {PROJECT_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </Select>
          </FormField>
        </div>
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} />
        </FormField>
        <FormField label="Description" error={errors.description?.message}>
          <Textarea {...register('description')} rows={3} />
        </FormField>
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Start Date" required error={errors.start_date?.message}>
            <Input type="date" {...register('start_date')} />
          </FormField>
          <FormField label="End Date" required error={errors.end_date?.message}>
            <Input type="date" {...register('end_date')} />
          </FormField>
        </div>
        <FormField label="Partner" error={errors.partner_id?.message}>
          <Select {...register('partner_id')}>
            <option value="">— None —</option>
            {(partnerList?.data ?? []).map((p) => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </Select>
        </FormField>
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Budget (IDR)" error={errors.budget?.message}>
            <Input type="number" step="0.01" {...register('budget')} />
          </FormField>
          <FormField label="Earning (IDR)" error={errors.earning?.message}>
            <Input type="number" step="0.01" {...register('earning')} />
          </FormField>
        </div>
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/projects')}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Save
          </Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
