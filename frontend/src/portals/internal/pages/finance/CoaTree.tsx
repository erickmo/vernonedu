import { useMemo, useState } from 'react'
import { ChevronRight, ChevronDown, Plus } from 'lucide-react'
import {
  useCoaTree,
  useCreateCoaAccount,
} from '@/lib/api/finance-coa'
import { COA_ACCOUNT_TYPES, type CoaTreeNode, type CoaAccountType } from '@/types/coa'
import { createCoaSchema } from '@/schemas/coa'
import RoleGate from '@/components/shared/RoleGate'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const TYPE_BADGE_CLASS: Record<CoaAccountType, string> = {
  asset: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  liability: 'bg-amber-50 text-amber-700 border-amber-200',
  equity: 'bg-purple-50 text-purple-700 border-purple-200',
  revenue: 'bg-blue-50 text-blue-700 border-blue-200',
  expense: 'bg-red-50 text-red-700 border-red-200',
}

interface NodeProps {
  node: CoaTreeNode
  depth: number
  expanded: Set<string>
  onToggle: (id: string) => void
}

function CoaNode({ node, depth, expanded, onToggle }: NodeProps) {
  const hasChildren = (node.children?.length ?? 0) > 0
  const isOpen = expanded.has(node.id)
  return (
    <div>
      <div
        className="flex items-center gap-2 py-1.5 px-2 hover:bg-neutral-50 rounded-md"
        style={{ paddingLeft: `${depth * 18 + 8}px` }}
      >
        {hasChildren ? (
          <button
            type="button"
            onClick={() => onToggle(node.id)}
            className="text-neutral-500 hover:text-neutral-800"
            aria-label={isOpen ? 'Collapse' : 'Expand'}
          >
            {isOpen ? (
              <ChevronDown className="w-4 h-4" />
            ) : (
              <ChevronRight className="w-4 h-4" />
            )}
          </button>
        ) : (
          <span className="w-4" />
        )}
        <span className="font-mono text-xs text-neutral-700 w-20">{node.code}</span>
        <span className="text-sm text-neutral-900 flex-1">{node.name}</span>
        <span
          className={`text-[10px] uppercase tracking-wide px-2 py-0.5 rounded border ${TYPE_BADGE_CLASS[node.type] ?? 'bg-gray-50 text-gray-700 border-gray-200'}`}
        >
          {node.type}
        </span>
        {!node.is_active && (
          <span className="text-[10px] text-neutral-400 italic">inactive</span>
        )}
      </div>
      {hasChildren && isOpen && (
        <div>
          {node.children!.map((c) => (
            <CoaNode
              key={c.id}
              node={c}
              depth={depth + 1}
              expanded={expanded}
              onToggle={onToggle}
            />
          ))}
        </div>
      )}
    </div>
  )
}

export default function CoaTree() {
  const { data: tree, isLoading } = useCoaTree()
  const createMut = useCreateCoaAccount()
  const [expanded, setExpanded] = useState<Set<string>>(new Set())
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({
    code: '',
    name: '',
    type: 'asset' as CoaAccountType,
    parent_id: '',
  })
  const [error, setError] = useState<string | null>(null)

  const allIds = useMemo(() => {
    const ids: string[] = []
    const walk = (n: CoaTreeNode) => {
      ids.push(n.id)
      n.children?.forEach(walk)
    }
    tree?.forEach(walk)
    return ids
  }, [tree])

  const onToggle = (id: string) => {
    setExpanded((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const expandAll = () => setExpanded(new Set(allIds))
  const collapseAll = () => setExpanded(new Set())

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    const parsed = createCoaSchema.safeParse({
      ...form,
      parent_id: form.parent_id || undefined,
    })
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    createMut.mutate(
      {
        ...parsed.data,
        parent_id: parsed.data.parent_id || null,
      },
      {
        onSuccess: () => {
          setShowForm(false)
          setForm({ code: '', name: '', type: 'asset', parent_id: '' })
        },
        onError: (err) => setError((err as Error).message),
      },
    )
  }

  return (
    <div className="space-y-4">
      <PageHeader
        title="Chart of Accounts"
        subtitle="Pohon akun keuangan (CoA) — sumber kebenaran semua jurnal."
        actions={
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={expandAll}
              className="px-2.5 py-1 text-xs border border-neutral-200 rounded-md hover:bg-neutral-50"
            >
              Expand all
            </button>
            <button
              type="button"
              onClick={collapseAll}
              className="px-2.5 py-1 text-xs border border-neutral-200 rounded-md hover:bg-neutral-50"
            >
              Collapse all
            </button>
            <RoleGate action="create" resource="coa">
              <button
                type="button"
                onClick={() => setShowForm((v) => !v)}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700"
              >
                <Plus className="w-4 h-4" /> New Account
              </button>
            </RoleGate>
          </div>
        }
      />

      {showForm && (
        <form
          onSubmit={onSubmit}
          className="bg-white border border-neutral-200 rounded-lg p-4 space-y-3"
        >
          <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Code
              </label>
              <input
                type="text"
                value={form.code}
                onChange={(e) => setForm({ ...form, code: e.target.value })}
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
                placeholder="1100"
              />
            </div>
            <div className="md:col-span-2">
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Name
              </label>
              <input
                type="text"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
                placeholder="Kas"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Type
              </label>
              <select
                value={form.type}
                onChange={(e) =>
                  setForm({ ...form, type: e.target.value as CoaAccountType })
                }
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md bg-white"
              >
                {COA_ACCOUNT_TYPES.map((t) => (
                  <option key={t} value={t}>
                    {t}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-neutral-600 mb-1">
              Parent ID (optional UUID)
            </label>
            <input
              type="text"
              value={form.parent_id}
              onChange={(e) => setForm({ ...form, parent_id: e.target.value })}
              className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md font-mono"
              placeholder="leave blank for root"
            />
          </div>
          {error && <p className="text-xs text-red-600">{error}</p>}
          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setShowForm(false)}
              className="px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={createMut.isPending}
              className="px-3 py-1.5 text-sm font-medium text-white bg-brand-600 rounded-md hover:bg-brand-700 disabled:opacity-50"
            >
              {createMut.isPending ? 'Saving…' : 'Create'}
            </button>
          </div>
        </form>
      )}

      <div className="bg-white border border-neutral-200 rounded-lg p-2 min-h-[300px]">
        {isLoading ? (
          <div className="py-12 flex justify-center">
            <LoadingSpinner size="md" />
          </div>
        ) : !tree || tree.length === 0 ? (
          <div className="py-12 text-center text-sm text-neutral-500">
            No CoA accounts yet.
          </div>
        ) : (
          tree.map((node) => (
            <CoaNode
              key={node.id}
              node={node}
              depth={0}
              expanded={expanded}
              onToggle={onToggle}
            />
          ))
        )}
      </div>
    </div>
  )
}
