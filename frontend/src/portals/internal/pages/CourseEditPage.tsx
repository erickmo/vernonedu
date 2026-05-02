import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
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
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import RoleGate from '@/components/shared/RoleGate'
import { updateMasterCourseSchema, FIELDS, type UpdateMasterCourseInput } from '@/schemas/mastercourse'
import { useMasterCourse, useUpdateMasterCourse, useArchiveMasterCourse } from '@/lib/api/curriculum'

export default function CourseEditPage() {
  const navigate = useNavigate()
  const { id = '' } = useParams<{ id: string }>()
  const { data, isLoading } = useMasterCourse(id)
  const update = useUpdateMasterCourse(id)
  const archive = useArchiveMasterCourse()

  const {
    register, handleSubmit, control, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateMasterCourseInput>({
    resolver: zodResolver(updateMasterCourseSchema),
  })

  useEffect(() => {
    if (data) {
      reset({
        course_code: data.course_code,
        course_name: data.course_name,
        field: data.field as any,
        core_competencies: data.core_competencies ?? [],
        description: data.description,
        supporting_app_url: data.supporting_app_url ?? '',
      })
    }
  }, [data, reset])

  async function onSubmit(values: UpdateMasterCourseInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Course updated')
      navigate(`/internal/courses/${id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update course')
    }
  }

  async function onArchive() {
    if (!confirm('Archive this course? It will be hidden from active list.')) return
    try {
      await archive.mutateAsync(id)
      toast.success('Course archived')
      navigate('/internal/courses')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to archive')
    }
  }

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Academic', to: '/internal/academic' },
    { label: 'Courses', to: '/internal/courses' },
    { label: data.course_code, to: `/internal/courses/${id}` },
    { label: 'Edit' },
  ]

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Edit Course"
      subtitle={data.course_code}
    >
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Course Code" required error={errors.course_code?.message}>
          <Input {...register('course_code')} />
        </FormField>
        <FormField label="Course Name" required error={errors.course_name?.message}>
          <Input {...register('course_name')} />
        </FormField>
        <FormField label="Field" required error={errors.field?.message}>
          <Select {...register('field')}>
            {FIELDS.map((f) => <option key={f} value={f}>{f}</option>)}
          </Select>
        </FormField>
        <FormField label="Core Competencies">
          <Controller
            name="core_competencies"
            control={control}
            render={({ field }) => (
              <MultiInput value={field.value ?? []} onChange={field.onChange} />
            )}
          />
        </FormField>
        <FormField label="Description" error={errors.description?.message}>
          <Textarea {...register('description')} rows={4} />
        </FormField>
        <FormField label="Supporting App URL" error={errors.supporting_app_url?.message}>
          <Input {...register('supporting_app_url')} />
        </FormField>

        <div className="flex gap-2 pt-2 border-t border-neutral-100">
          <Button type="button" variant="secondary" onClick={() => navigate(`/internal/courses/${id}`)}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Save
          </Button>
          {data.status === 'active' && (
            <RoleGate action="delete" resource="mastercourse">
              <Button type="button" variant="danger" onClick={onArchive}>
                Archive
              </Button>
            </RoleGate>
          )}
        </div>
      </form>
    </StandardPageLayout>
  )
}
