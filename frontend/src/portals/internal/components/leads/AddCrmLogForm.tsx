import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Input from '@/components/ui/Input'
import Button from '@/components/ui/Button'
import { addCrmLogSchema, type AddCrmLogInput } from '@/schemas/lead'
import { CONTACT_METHODS } from '@/types/crmlog'
import { useAddCrmLog } from '@/lib/api/lead'
import { useAuth } from '@/lib/auth/useAuth'

interface Props {
  leadId: string
}

function toRfc3339(date: string): string {
  // date input gives YYYY-MM-DD; convert to RFC3339 at midnight UTC
  return new Date(`${date}T00:00:00Z`).toISOString()
}

export default function AddCrmLogForm({ leadId }: Props) {
  const { user } = useAuth()
  const addLog = useAddCrmLog(leadId)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<AddCrmLogInput>({
    resolver: zodResolver(addCrmLogSchema),
    defaultValues: {
      contacted_by_id: user?.id ?? '',
      contact_method: 'call',
      response: '',
      follow_up_date: '',
    },
  })

  async function onSubmit(values: AddCrmLogInput) {
    try {
      const payload: AddCrmLogInput = {
        ...values,
        contacted_by_id: user?.id ?? values.contacted_by_id,
        follow_up_date: values.follow_up_date
          ? toRfc3339(values.follow_up_date)
          : null,
      }
      await addLog.mutateAsync(payload)
      toast.success('CRM log added')
      reset({
        contacted_by_id: user?.id ?? '',
        contact_method: 'call',
        response: '',
        follow_up_date: '',
      })
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to add log')
    }
  }

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      className="bg-white border border-neutral-100 rounded-lg p-4 space-y-3"
    >
      <input type="hidden" {...register('contacted_by_id')} />
      <div className="grid grid-cols-2 gap-3">
        <FormField label="Contact Method" required error={errors.contact_method?.message}>
          <Select {...register('contact_method')}>
            {CONTACT_METHODS.map((m) => <option key={m} value={m}>{m}</option>)}
          </Select>
        </FormField>
        <FormField label="Follow-up Date" error={errors.follow_up_date?.message}>
          <Input type="date" {...register('follow_up_date')} />
        </FormField>
      </div>
      <FormField label="Response / Notes" required error={errors.response?.message}>
        <Textarea {...register('response')} rows={3} placeholder="What did the lead say?" />
      </FormField>
      <div className="flex justify-end">
        <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
          Add Log
        </Button>
      </div>
    </form>
  )
}
