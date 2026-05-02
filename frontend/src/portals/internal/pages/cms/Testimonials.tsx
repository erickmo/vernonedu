import { useState } from 'react'
import { Plus, Pencil, Trash2, Star } from 'lucide-react'
import { toast } from 'sonner'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import FormField from '@/components/shared/FormField'
import FormModal from '@/components/shared/FormModal'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import RoleGate from '@/components/shared/RoleGate'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import type { CmsTestimonial } from '@/types/cmstestimonial'
import {
  useCmsTestimonials,
  useCreateCmsTestimonial,
  useUpdateCmsTestimonial,
  useDeleteCmsTestimonial,
} from '@/lib/api/cms'

interface FormState {
  student_name: string
  course_id: string
  quote: string
  rating: number
  photo_url: string
  is_featured: boolean
}

const EMPTY: FormState = {
  student_name: '',
  course_id: '',
  quote: '',
  rating: 5,
  photo_url: '',
  is_featured: false,
}

export default function Testimonials() {
  const [featuredOnly, setFeaturedOnly] = useState(false)
  const { data, isLoading } = useCmsTestimonials({
    is_featured: featuredOnly ? true : undefined,
  })

  const [editing, setEditing] = useState<CmsTestimonial | null>(null)
  const [open, setOpen] = useState(false)
  const [form, setForm] = useState<FormState>(EMPTY)
  const [deleteId, setDeleteId] = useState<string | null>(null)

  const create = useCreateCmsTestimonial()
  const update = useUpdateCmsTestimonial(editing?.id ?? '')
  const del = useDeleteCmsTestimonial()

  function openCreate() {
    setEditing(null)
    setForm(EMPTY)
    setOpen(true)
  }
  function openEdit(t: CmsTestimonial) {
    setEditing(t)
    setForm({
      student_name: t.student_name,
      course_id: t.course_id ?? '',
      quote: t.quote,
      rating: t.rating,
      photo_url: t.photo_url ?? '',
      is_featured: t.is_featured,
    })
    setOpen(true)
  }

  async function onSubmit() {
    try {
      if (editing) await update.mutateAsync(form)
      else await create.mutateAsync(form)
      toast.success(editing ? 'Testimonial updated' : 'Testimonial created')
      setOpen(false)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed')
    }
  }

  async function onDelete() {
    if (!deleteId) return
    try {
      await del.mutateAsync(deleteId)
      toast.success('Testimonial deleted')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed')
    } finally {
      setDeleteId(null)
    }
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="Testimonials"
        subtitle="Student reviews on the website"
        actions={
          <RoleGate action="create" resource="cms_testimonial">
            <Button onClick={openCreate}>
              <Plus className="w-4 h-4" /> Add Testimonial
            </Button>
          </RoleGate>
        }
      />

      <label className="inline-flex items-center gap-2 text-sm text-neutral-700">
        <input
          type="checkbox"
          checked={featuredOnly}
          onChange={(e) => setFeaturedOnly(e.target.checked)}
        />
        Featured only
      </label>

      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {(data ?? []).length === 0 && (
            <div className="bg-white rounded-xl border border-neutral-100 p-6 text-sm text-neutral-500 md:col-span-2">
              No testimonials
            </div>
          )}
          {(data ?? []).map((t) => (
            <div key={t.id} className="bg-white rounded-xl border border-neutral-100 p-4">
              <div className="flex justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-neutral-900">{t.student_name}</div>
                  <div className="flex gap-0.5 mt-0.5">
                    {Array.from({ length: 5 }).map((_, i) => (
                      <Star
                        key={i}
                        className={`w-3.5 h-3.5 ${
                          i < t.rating ? 'fill-yellow-400 text-yellow-400' : 'text-neutral-300'
                        }`}
                      />
                    ))}
                    {t.is_featured && (
                      <span className="ml-2 text-xs text-brand-600 font-medium">★ Featured</span>
                    )}
                  </div>
                  <div className="text-sm text-neutral-700 mt-2 italic">"{t.quote}"</div>
                </div>
                <div className="flex gap-1 shrink-0">
                  <RoleGate action="update" resource="cms_testimonial">
                    <button
                      onClick={() => openEdit(t)}
                      className="p-2 text-neutral-500 hover:text-brand-600"
                      aria-label="Edit"
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                  </RoleGate>
                  <RoleGate action="delete" resource="cms_testimonial">
                    <button
                      onClick={() => setDeleteId(t.id)}
                      className="p-2 text-neutral-500 hover:text-red-600"
                      aria-label="Delete"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </RoleGate>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <FormModal
        open={open}
        onOpenChange={setOpen}
        title={editing ? 'Edit Testimonial' : 'New Testimonial'}
        onSubmit={onSubmit}
        loading={create.isPending || update.isPending}
      >
        <FormField label="Student Name" required>
          <Input
            value={form.student_name}
            onChange={(e) => setForm({ ...form, student_name: e.target.value })}
          />
        </FormField>
        <FormField label="Course ID">
          <Input
            value={form.course_id}
            onChange={(e) => setForm({ ...form, course_id: e.target.value })}
          />
        </FormField>
        <FormField label="Quote" required>
          <Textarea
            value={form.quote}
            onChange={(e) => setForm({ ...form, quote: e.target.value })}
            rows={3}
          />
        </FormField>
        <FormField label="Rating (1-5)" required>
          <Input
            type="number"
            min={1}
            max={5}
            value={form.rating}
            onChange={(e) => setForm({ ...form, rating: parseInt(e.target.value || '0', 10) })}
          />
        </FormField>
        <FormField label="Photo URL">
          <Input
            value={form.photo_url}
            onChange={(e) => setForm({ ...form, photo_url: e.target.value })}
          />
        </FormField>
        <label className="inline-flex items-center gap-2 text-sm text-neutral-700">
          <input
            type="checkbox"
            checked={form.is_featured}
            onChange={(e) => setForm({ ...form, is_featured: e.target.checked })}
          />
          Featured
        </label>
      </FormModal>

      <ConfirmDialog
        open={!!deleteId}
        onConfirm={onDelete}
        onCancel={() => setDeleteId(null)}
        title="Delete testimonial?"
        description="This cannot be undone."
        confirmLabel="Delete"
        destructive
      />
    </div>
  )
}
