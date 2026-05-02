import { useNavigate } from 'react-router-dom'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import MultiInput from '@/components/shared/MultiInput'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import { createMasterCourseSchema, FIELDS, type CreateMasterCourseInput } from '@/schemas/mastercourse'
import { useCreateMasterCourse } from '@/lib/api/curriculum'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Academic', to: '/internal/academic' },
  { label: 'Courses', to: '/internal/courses' },
  { label: 'New Course' },
]

export default function CourseCreatePage() {
  const navigate = useNavigate()
  const create = useCreateMasterCourse()

  const {
    register, handleSubmit, control,
    formState: { errors, isSubmitting },
  } = useForm<CreateMasterCourseInput>({
    resolver: zodResolver(createMasterCourseSchema),
    defaultValues: {
      course_code: '',
      course_name: '',
      field: 'Tech',
      core_competencies: [],
      description: '',
      supporting_app_url: '',
    },
  })

  async function onSubmit(values: CreateMasterCourseInput) {
    try {
      const created = await create.mutateAsync(values)
      toast.success('Course created')
      navigate(`/internal/courses/${created.id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create course')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Add Course"
      subtitle="Create a new master course"
    >
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Course Code" required error={errors.course_code?.message}>
          <Input {...register('course_code')} placeholder="MC-001" />
        </FormField>

        <FormField label="Course Name" required error={errors.course_name?.message}>
          <Input {...register('course_name')} placeholder="Web Development" />
        </FormField>

        <FormField label="Field" required error={errors.field?.message}>
          <Select {...register('field')}>
            {FIELDS.map((f) => <option key={f} value={f}>{f}</option>)}
          </Select>
        </FormField>

        <FormField label="Core Competencies" error={errors.core_competencies?.message as string | undefined}>
          <Controller
            name="core_competencies"
            control={control}
            render={({ field }) => (
              <MultiInput value={field.value ?? []} onChange={field.onChange} placeholder="Type and press Enter" />
            )}
          />
        </FormField>

        <FormField label="Description" error={errors.description?.message}>
          <Textarea {...register('description')} rows={4} />
        </FormField>

        <FormField label="Supporting App URL" error={errors.supporting_app_url?.message}>
          <Input {...register('supporting_app_url')} placeholder="https://..." />
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/courses')}>
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
