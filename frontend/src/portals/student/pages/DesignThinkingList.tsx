import { useState } from 'react'
import { toast } from 'sonner'
import { Plus, Trash2, Pencil, Check, X } from 'lucide-react'
import {
  useDesignThinkings,
  useCreateDesignThinking,
  useUpdateDesignThinking,
  useDeleteDesignThinking,
} from '@/lib/api/designthinking'
import { createDesignThinkingSchema } from '@/schemas/designthinking'
import Input from '@/components/ui/Input'
import Button from '@/components/ui/Button'

export default function DesignThinkingList() {
  const { data: items = [], isLoading } = useDesignThinkings()
  const create = useCreateDesignThinking()
  const remove = useDeleteDesignThinking()

  const [newName, setNewName] = useState('')
  const [editId, setEditId] = useState<string | null>(null)
  const [editName, setEditName] = useState('')

  async function onCreate() {
    const parsed = createDesignThinkingSchema.safeParse({ name: newName })
    if (!parsed.success) {
      toast.error(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    try {
      await create.mutateAsync(parsed.data)
      toast.success('Design Thinking project created')
      setNewName('')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create')
    }
  }

  async function onDelete(id: string) {
    if (!confirm('Delete project?')) return
    try {
      await remove.mutateAsync(id)
      toast.success('Deleted')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete')
    }
  }

  return (
    <div className="max-w-3xl space-y-5">
      <div>
        <h1 className="text-2xl font-bold">My Design Thinking Projects</h1>
        <p className="text-sm text-neutral-500 mt-1">
          Empathize → Define → Ideate → Prototype → Test.
        </p>
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 p-4 flex gap-2">
        <Input
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
          placeholder="New project name…"
          className="flex-1"
        />
        <Button onClick={onCreate} loading={create.isPending}>
          <Plus className="w-4 h-4" /> Create
        </Button>
      </div>

      <div className="bg-white rounded-xl border border-neutral-100">
        {isLoading ? (
          <div className="p-4 text-sm text-neutral-500">Loading…</div>
        ) : items.length === 0 ? (
          <div className="p-6 text-sm text-neutral-400 text-center">No projects yet.</div>
        ) : (
          <ul className="divide-y">
            {items.map((c) => (
              <DTRow
                key={c.id}
                id={c.id}
                name={c.name}
                isEditing={editId === c.id}
                editName={editName}
                onStartEdit={() => {
                  setEditId(c.id)
                  setEditName(c.name)
                }}
                onCancel={() => setEditId(null)}
                onChangeEdit={setEditName}
                onSaveDone={() => setEditId(null)}
                onDelete={() => onDelete(c.id)}
              />
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}

interface RowProps {
  id: string
  name: string
  isEditing: boolean
  editName: string
  onStartEdit: () => void
  onCancel: () => void
  onChangeEdit: (v: string) => void
  onSaveDone: () => void
  onDelete: () => void
}

function DTRow({
  id, name, isEditing, editName,
  onStartEdit, onCancel, onChangeEdit, onSaveDone, onDelete,
}: RowProps) {
  const update = useUpdateDesignThinking(id)

  async function onSave() {
    const parsed = createDesignThinkingSchema.safeParse({ name: editName })
    if (!parsed.success) {
      toast.error(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    try {
      await update.mutateAsync(parsed.data)
      toast.success('Updated')
      onSaveDone()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  return (
    <li className="flex items-center gap-3 px-4 py-3">
      {isEditing ? (
        <>
          <Input
            value={editName}
            onChange={(e) => onChangeEdit(e.target.value)}
            className="flex-1"
          />
          <button onClick={onSave} className="text-green-600" aria-label="Save">
            <Check className="w-4 h-4" />
          </button>
          <button onClick={onCancel} className="text-neutral-500" aria-label="Cancel">
            <X className="w-4 h-4" />
          </button>
        </>
      ) : (
        <>
          <span className="flex-1 text-sm">{name}</span>
          <button onClick={onStartEdit} className="text-neutral-500 hover:text-neutral-700" aria-label="Edit">
            <Pencil className="w-4 h-4" />
          </button>
          <button onClick={onDelete} className="text-red-600 hover:text-red-800" aria-label="Delete">
            <Trash2 className="w-4 h-4" />
          </button>
        </>
      )}
    </li>
  )
}
