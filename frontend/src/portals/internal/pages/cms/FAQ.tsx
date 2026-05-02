import { useState } from 'react'
import { Plus, Pencil, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import FormField from '@/components/shared/FormField'
import FormModal from '@/components/shared/FormModal'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import MultiInput from '@/components/shared/MultiInput'
import RoleGate from '@/components/shared/RoleGate'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import { FAQ_CATEGORIES, type CmsFaq } from '@/types/cmsfaq'
import {
  useCmsFaqs,
  useCreateCmsFaq,
  useUpdateCmsFaq,
  useDeleteCmsFaq,
} from '@/lib/api/cms'

interface FormState {
  question: string
  answer: string
  category: string
  page_slugs: string[]
  sort_order: number
}

const EMPTY: FormState = {
  question: '',
  answer: '',
  category: '',
  page_slugs: [],
  sort_order: 0,
}

export default function FAQ() {
  const [category, setCategory] = useState('')
  const [pageSlug, setPageSlug] = useState('')
  const { data, isLoading } = useCmsFaqs({
    category: category || undefined,
    page_slug: pageSlug || undefined,
  })

  const [editing, setEditing] = useState<CmsFaq | null>(null)
  const [open, setOpen] = useState(false)
  const [form, setForm] = useState<FormState>(EMPTY)
  const [deleteId, setDeleteId] = useState<string | null>(null)

  const create = useCreateCmsFaq()
  const update = useUpdateCmsFaq(editing?.id ?? '')
  const del = useDeleteCmsFaq()

  function openCreate() {
    setEditing(null)
    setForm(EMPTY)
    setOpen(true)
  }

  function openEdit(f: CmsFaq) {
    setEditing(f)
    setForm({
      question: f.question,
      answer: f.answer,
      category: f.category ?? '',
      page_slugs: f.page_slugs ?? [],
      sort_order: f.sort_order ?? 0,
    })
    setOpen(true)
  }

  async function onSubmit() {
    try {
      if (editing) await update.mutateAsync(form)
      else await create.mutateAsync(form)
      toast.success(editing ? 'FAQ updated' : 'FAQ created')
      setOpen(false)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed')
    }
  }

  async function onDelete() {
    if (!deleteId) return
    try {
      await del.mutateAsync(deleteId)
      toast.success('FAQ deleted')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed')
    } finally {
      setDeleteId(null)
    }
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="FAQ"
        subtitle="Frequently asked questions"
        actions={
          <RoleGate action="create" resource="cms_faq">
            <Button onClick={openCreate}>
              <Plus className="w-4 h-4" /> Add FAQ
            </Button>
          </RoleGate>
        }
      />

      <div className="flex gap-2">
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
        >
          <option value="">All categories</option>
          {FAQ_CATEGORIES.map((c) => (
            <option key={c} value={c}>{c}</option>
          ))}
        </select>
        <input
          value={pageSlug}
          onChange={(e) => setPageSlug(e.target.value)}
          placeholder="Filter by page slug"
          className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
        />
      </div>

      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <div className="space-y-2">
          {(data ?? []).length === 0 && (
            <div className="bg-white rounded-xl border border-neutral-100 p-6 text-sm text-neutral-500">
              No FAQ entries
            </div>
          )}
          {(data ?? []).map((f) => (
            <div key={f.id} className="bg-white rounded-xl border border-neutral-100 p-4">
              <div className="flex justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-neutral-900">{f.question}</div>
                  <div className="text-sm text-neutral-600 mt-1 whitespace-pre-wrap">
                    {f.answer}
                  </div>
                  <div className="text-xs text-neutral-400 mt-2">
                    {f.category} · order {f.sort_order} · pages: {(f.page_slugs ?? []).join(', ') || '-'}
                  </div>
                </div>
                <div className="flex gap-2 shrink-0">
                  <RoleGate action="update" resource="cms_faq">
                    <button
                      onClick={() => openEdit(f)}
                      className="p-2 text-neutral-500 hover:text-brand-600"
                      aria-label="Edit"
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                  </RoleGate>
                  <RoleGate action="delete" resource="cms_faq">
                    <button
                      onClick={() => setDeleteId(f.id)}
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
        title={editing ? 'Edit FAQ' : 'New FAQ'}
        onSubmit={onSubmit}
        loading={create.isPending || update.isPending}
      >
        <FormField label="Question" required>
          <Input
            value={form.question}
            onChange={(e) => setForm({ ...form, question: e.target.value })}
          />
        </FormField>
        <FormField label="Answer" required>
          <Textarea
            value={form.answer}
            onChange={(e) => setForm({ ...form, answer: e.target.value })}
            rows={4}
          />
        </FormField>
        <FormField label="Category">
          <Input
            value={form.category}
            onChange={(e) => setForm({ ...form, category: e.target.value })}
            placeholder="e.g. enrollment"
          />
        </FormField>
        <FormField label="Page Slugs">
          <MultiInput
            value={form.page_slugs}
            onChange={(next) => setForm({ ...form, page_slugs: next })}
            placeholder="Add page slug + Enter"
          />
        </FormField>
        <FormField label="Sort Order">
          <Input
            type="number"
            value={form.sort_order}
            onChange={(e) =>
              setForm({ ...form, sort_order: parseInt(e.target.value || '0', 10) })
            }
          />
        </FormField>
      </FormModal>

      <ConfirmDialog
        open={!!deleteId}
        onConfirm={onDelete}
        onCancel={() => setDeleteId(null)}
        title="Delete FAQ?"
        description="This cannot be undone."
        confirmLabel="Delete"
        destructive
      />
    </div>
  )
}
