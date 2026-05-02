import { useState } from 'react'
import { toast } from 'sonner'
import { Plus, Trash2 } from 'lucide-react'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import {
  useItems,
  useCreateItem,
  useDeleteItem,
} from '@/lib/api/inventory'
import { createItemSchema } from '@/schemas/item'

const breadcrumbs: BreadcrumbItem[] = [{ label: 'Inventory' }]

export default function InventoryPage() {
  const [businessId, setBusinessId] = useState('')
  const [draft, setDraft] = useState({
    canvas_type: 'inventory',
    section_id: 'items',
    text: '',
    note: '',
  })

  const { data: items = [], isLoading } = useItems(
    businessId ? { business_id: businessId } : undefined,
  )
  const create = useCreateItem()
  const remove = useDeleteItem()

  async function onCreate() {
    const parsed = createItemSchema.safeParse({ business_id: businessId, ...draft })
    if (!parsed.success) {
      toast.error(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    try {
      await create.mutateAsync(parsed.data)
      toast.success('Item created')
      setDraft({ canvas_type: 'inventory', section_id: 'items', text: '', note: '' })
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create')
    }
  }

  async function onDelete(id: string) {
    if (!confirm('Delete item?')) return
    try {
      await remove.mutateAsync(id)
      toast.success('Item deleted')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Inventory"
      subtitle="Manage canvas items / inventory across businesses"
    >
      <div className="max-w-4xl space-y-4">
        <div className="bg-white rounded-xl border border-neutral-100 p-4 space-y-3">
          <div className="text-sm font-medium">Business ID</div>
          <Input
            value={businessId}
            onChange={(e) => setBusinessId(e.target.value)}
            placeholder="UUID of business to scope items"
          />
        </div>

        {businessId && (
          <>
            <div className="bg-white rounded-xl border border-neutral-100 p-4 space-y-3">
              <div className="text-sm font-medium">Add Item</div>
              <div className="grid grid-cols-2 gap-2">
                <Input
                  value={draft.canvas_type}
                  onChange={(e) => setDraft({ ...draft, canvas_type: e.target.value })}
                  placeholder="canvas_type (e.g. inventory)"
                />
                <Input
                  value={draft.section_id}
                  onChange={(e) => setDraft({ ...draft, section_id: e.target.value })}
                  placeholder="section_id"
                />
              </div>
              <Input
                value={draft.text}
                onChange={(e) => setDraft({ ...draft, text: e.target.value })}
                placeholder="Item text / description"
              />
              <Textarea
                rows={2}
                value={draft.note}
                onChange={(e) => setDraft({ ...draft, note: e.target.value })}
                placeholder="Note (optional)"
              />
              <Button onClick={onCreate} loading={create.isPending}>
                <Plus className="w-4 h-4" /> Add Item
              </Button>
            </div>

            <div className="bg-white rounded-xl border border-neutral-100 p-4">
              <div className="text-sm font-medium mb-3">Items ({items.length})</div>
              {isLoading ? (
                <div className="text-sm text-neutral-500">Loading…</div>
              ) : items.length === 0 ? (
                <div className="text-sm text-neutral-400">No items yet.</div>
              ) : (
                <ul className="divide-y">
                  {items.map((it) => (
                    <li key={it.id} className="py-2 flex items-start gap-3">
                      <div className="flex-1">
                        <div className="text-sm">{it.text}</div>
                        <div className="text-xs text-neutral-500 mt-0.5">
                          {it.canvas_type} / {it.section_id}
                          {it.note ? ` • ${it.note}` : ''}
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => onDelete(it.id)}
                        className="text-red-600 hover:text-red-800"
                        aria-label="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </>
        )}
      </div>
    </StandardPageLayout>
  )
}
