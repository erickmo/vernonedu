import { useState } from 'react'
import { Plus, Pencil } from 'lucide-react'
import {
  useFinanceAccounts,
  useCreateFinanceAccount,
  useUpdateFinanceAccount,
} from '@/lib/api/finance-coa'
import {
  createFinanceAccountSchema,
  updateFinanceAccountSchema,
} from '@/schemas/financeaccount'
import {
  FINANCE_ACCOUNT_KINDS,
  type FinanceAccount,
  type FinanceAccountKind,
} from '@/types/financeaccount'
import RoleGate from '@/components/shared/RoleGate'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface CreateForm {
  code: string
  name: string
  kind: FinanceAccountKind
}

const EMPTY_CREATE: CreateForm = { code: '', name: '', kind: 'bank' }

export default function FinanceAccounts() {
  const { data, isLoading } = useFinanceAccounts()
  const createMut = useCreateFinanceAccount()
  const updateMut = useUpdateFinanceAccount()
  const [showCreate, setShowCreate] = useState(false)
  const [createForm, setCreateForm] = useState<CreateForm>(EMPTY_CREATE)
  const [createError, setCreateError] = useState<string | null>(null)
  const [editing, setEditing] = useState<FinanceAccount | null>(null)
  const [editError, setEditError] = useState<string | null>(null)

  const onCreate = (e: React.FormEvent) => {
    e.preventDefault()
    setCreateError(null)
    const parsed = createFinanceAccountSchema.safeParse(createForm)
    if (!parsed.success) {
      setCreateError(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    createMut.mutate(
      { code: parsed.data.code, name: parsed.data.name, type: 'asset' },
      {
        onSuccess: () => {
          setShowCreate(false)
          setCreateForm(EMPTY_CREATE)
        },
        onError: (err) => setCreateError((err as Error).message),
      },
    )
  }

  const onUpdate = (e: React.FormEvent) => {
    e.preventDefault()
    if (!editing) return
    setEditError(null)
    const parsed = updateFinanceAccountSchema.safeParse({
      name: editing.name,
      is_active: editing.is_active,
    })
    if (!parsed.success) {
      setEditError(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    updateMut.mutate(
      { id: editing.id, payload: parsed.data },
      {
        onSuccess: () => setEditing(null),
        onError: (err) => setEditError((err as Error).message),
      },
    )
  }

  return (
    <div className="space-y-4">
      <PageHeader
        title="Bank & Cash Accounts"
        subtitle="Akun kas dan bank — sumber dana untuk transaksi keuangan."
        actions={
          <RoleGate action="create" resource="finance_account">
            <button
              type="button"
              onClick={() => setShowCreate((v) => !v)}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700"
            >
              <Plus className="w-4 h-4" /> New Account
            </button>
          </RoleGate>
        }
      />

      {showCreate && (
        <form
          onSubmit={onCreate}
          className="bg-white border border-neutral-200 rounded-lg p-4 space-y-3"
        >
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Code (e.g. 1101)
              </label>
              <input
                type="text"
                value={createForm.code}
                onChange={(e) => setCreateForm({ ...createForm, code: e.target.value })}
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Name
              </label>
              <input
                type="text"
                value={createForm.name}
                onChange={(e) => setCreateForm({ ...createForm, name: e.target.value })}
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
                placeholder="BCA Operasional"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Kind
              </label>
              <select
                value={createForm.kind}
                onChange={(e) =>
                  setCreateForm({
                    ...createForm,
                    kind: e.target.value as FinanceAccountKind,
                  })
                }
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md bg-white"
              >
                {FINANCE_ACCOUNT_KINDS.map((k) => (
                  <option key={k} value={k}>
                    {k}
                  </option>
                ))}
              </select>
            </div>
          </div>
          {createError && <p className="text-xs text-red-600">{createError}</p>}
          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setShowCreate(false)}
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

      <div className="bg-white border border-neutral-200 rounded-lg overflow-hidden">
        {isLoading ? (
          <div className="py-12 flex justify-center">
            <LoadingSpinner size="md" />
          </div>
        ) : !data || data.length === 0 ? (
          <div className="py-12 text-center text-sm text-neutral-500">
            No bank/cash accounts yet.
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 border-b border-neutral-200">
              <tr className="text-left text-xs text-neutral-500 uppercase">
                <th className="px-4 py-2">Code</th>
                <th className="px-4 py-2">Name</th>
                <th className="px-4 py-2">Type</th>
                <th className="px-4 py-2">Active</th>
                <th className="px-4 py-2 w-20"></th>
              </tr>
            </thead>
            <tbody>
              {data.map((acc) => (
                <tr key={acc.id} className="border-b border-neutral-100">
                  <td className="px-4 py-2 font-mono text-xs">{acc.code}</td>
                  <td className="px-4 py-2">{acc.name}</td>
                  <td className="px-4 py-2 text-xs uppercase text-neutral-500">
                    {acc.type}
                  </td>
                  <td className="px-4 py-2">
                    {acc.is_active ? (
                      <span className="text-xs text-emerald-700">Yes</span>
                    ) : (
                      <span className="text-xs text-neutral-400">No</span>
                    )}
                  </td>
                  <td className="px-4 py-2 text-right">
                    <RoleGate action="update" resource="finance_account">
                      <button
                        type="button"
                        onClick={() => setEditing(acc)}
                        className="p-1 text-neutral-500 hover:text-neutral-800"
                        aria-label="Edit"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                    </RoleGate>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {editing && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
          role="dialog"
        >
          <form
            onSubmit={onUpdate}
            className="bg-white rounded-lg p-5 w-full max-w-md space-y-3"
          >
            <h2 className="text-lg font-semibold">Edit Account</h2>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Name
              </label>
              <input
                type="text"
                value={editing.name}
                onChange={(e) => setEditing({ ...editing, name: e.target.value })}
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
              />
            </div>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={editing.is_active}
                onChange={(e) =>
                  setEditing({ ...editing, is_active: e.target.checked })
                }
              />
              Active
            </label>
            {editError && <p className="text-xs text-red-600">{editError}</p>}
            <div className="flex justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => setEditing(null)}
                className="px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={updateMut.isPending}
                className="px-3 py-1.5 text-sm font-medium text-white bg-brand-600 rounded-md hover:bg-brand-700 disabled:opacity-50"
              >
                {updateMut.isPending ? 'Saving…' : 'Save'}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  )
}
