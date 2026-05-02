import { useState } from 'react'
import { Plus } from 'lucide-react'
import {
  useFinanceTransactions,
  useCreateFinanceTransaction,
} from '@/lib/api/transaction'
import { useCoaAccounts } from '@/lib/api/finance-coa'
import { createTransactionSchema } from '@/schemas/transaction'
import { TRANSACTION_SOURCES } from '@/types/transaction'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import RoleGate from '@/components/shared/RoleGate'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const PAGE_SIZE = 25

interface CreateForm {
  description: string
  account_debit_id: string
  account_credit_id: string
  amount: string
  reference: string
  branch_id: string
  attachment_url: string
}

const EMPTY: CreateForm = {
  description: '',
  account_debit_id: '',
  account_credit_id: '',
  amount: '',
  reference: '',
  branch_id: '',
  attachment_url: '',
}

export default function Transactions() {
  const [page, setPage] = useState(1)
  const [accountId, setAccountId] = useState('')
  const [source, setSource] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState<CreateForm>(EMPTY)
  const [error, setError] = useState<string | null>(null)

  const { data, isLoading } = useFinanceTransactions({
    account_id: accountId || undefined,
    source: source || undefined,
    date_from: dateFrom || undefined,
    date_to: dateTo || undefined,
    offset: (page - 1) * PAGE_SIZE,
    limit: PAGE_SIZE,
  })
  const { data: accounts } = useCoaAccounts()
  const createMut = useCreateFinanceTransaction()

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    const parsed = createTransactionSchema.safeParse({
      ...form,
      amount: Number(form.amount),
    })
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? 'Invalid input')
      return
    }
    createMut.mutate(parsed.data, {
      onSuccess: () => {
        setShowForm(false)
        setForm(EMPTY)
      },
      onError: (err) => setError((err as Error).message),
    })
  }

  const rows = data?.data ?? []
  const total = data?.total ?? rows.length

  return (
    <div className="space-y-4">
      <PageHeader
        title="Transactions"
        subtitle="Daftar transaksi keuangan (manual + auto-posted)."
        actions={
          <RoleGate action="create" resource="transaction">
            <button
              type="button"
              onClick={() => setShowForm((v) => !v)}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700"
            >
              <Plus className="w-4 h-4" /> New Transaction
            </button>
          </RoleGate>
        }
      />

      <div className="flex items-center gap-2 flex-wrap">
        <select
          value={accountId}
          onChange={(e) => {
            setAccountId(e.target.value)
            setPage(1)
          }}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
        >
          <option value="">All accounts</option>
          {(accounts ?? []).map((a) => (
            <option key={a.id} value={a.id}>
              {a.code} — {a.name}
            </option>
          ))}
        </select>
        <select
          value={source}
          onChange={(e) => {
            setSource(e.target.value)
            setPage(1)
          }}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
        >
          <option value="">All sources</option>
          {TRANSACTION_SOURCES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <input
          type="date"
          value={dateFrom}
          onChange={(e) => {
            setDateFrom(e.target.value)
            setPage(1)
          }}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
        />
        <input
          type="date"
          value={dateTo}
          onChange={(e) => {
            setDateTo(e.target.value)
            setPage(1)
          }}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
        />
      </div>

      {showForm && (
        <form
          onSubmit={onSubmit}
          className="bg-white border border-neutral-200 rounded-lg p-4 space-y-3"
        >
          <div>
            <label className="block text-xs font-medium text-neutral-600 mb-1">
              Description
            </label>
            <input
              type="text"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
            />
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Debit account
              </label>
              <select
                value={form.account_debit_id}
                onChange={(e) =>
                  setForm({ ...form, account_debit_id: e.target.value })
                }
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md bg-white"
              >
                <option value="">— select —</option>
                {(accounts ?? []).map((a) => (
                  <option key={a.id} value={a.id}>
                    {a.code} — {a.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Credit account
              </label>
              <select
                value={form.account_credit_id}
                onChange={(e) =>
                  setForm({ ...form, account_credit_id: e.target.value })
                }
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md bg-white"
              >
                <option value="">— select —</option>
                {(accounts ?? []).map((a) => (
                  <option key={a.id} value={a.id}>
                    {a.code} — {a.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Amount (IDR)
              </label>
              <input
                type="number"
                value={form.amount}
                onChange={(e) => setForm({ ...form, amount: e.target.value })}
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Reference
              </label>
              <input
                type="text"
                value={form.reference}
                onChange={(e) => setForm({ ...form, reference: e.target.value })}
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-neutral-600 mb-1">
                Branch ID (UUID)
              </label>
              <input
                type="text"
                value={form.branch_id}
                onChange={(e) => setForm({ ...form, branch_id: e.target.value })}
                className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md font-mono"
              />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-neutral-600 mb-1">
              Attachment URL (optional)
            </label>
            <input
              type="text"
              value={form.attachment_url}
              onChange={(e) => setForm({ ...form, attachment_url: e.target.value })}
              className="w-full px-3 py-1.5 text-sm border border-neutral-200 rounded-md"
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

      <div className="bg-white border border-neutral-200 rounded-lg overflow-hidden">
        {isLoading ? (
          <div className="py-12 flex justify-center">
            <LoadingSpinner size="md" />
          </div>
        ) : rows.length === 0 ? (
          <div className="py-12 text-center text-sm text-neutral-500">
            No transactions for this filter.
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 border-b border-neutral-200">
              <tr className="text-left text-xs text-neutral-500 uppercase">
                <th className="px-4 py-2">Date</th>
                <th className="px-4 py-2">Description</th>
                <th className="px-4 py-2">Source</th>
                <th className="px-4 py-2">Reference</th>
                <th className="px-4 py-2 text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((tx) => (
                <tr key={tx.id} className="border-b border-neutral-100">
                  <td className="px-4 py-2 text-xs text-neutral-500">
                    {tx.created_at ? formatDate(tx.created_at) : '—'}
                  </td>
                  <td className="px-4 py-2">{tx.description}</td>
                  <td className="px-4 py-2 text-xs text-neutral-500">
                    {tx.source ?? 'manual'}
                  </td>
                  <td className="px-4 py-2 text-xs text-neutral-500 font-mono">
                    {tx.reference ?? '—'}
                  </td>
                  <td className="px-4 py-2 text-right font-mono font-semibold">
                    {formatCurrency(tx.amount)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="flex items-center justify-between text-xs text-neutral-500">
        <span>
          Showing {rows.length} of {total}
        </span>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-3 py-1 border border-neutral-200 rounded disabled:opacity-50"
          >
            Prev
          </button>
          <button
            type="button"
            onClick={() => setPage((p) => p + 1)}
            disabled={rows.length < PAGE_SIZE}
            className="px-3 py-1 border border-neutral-200 rounded disabled:opacity-50"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  )
}
