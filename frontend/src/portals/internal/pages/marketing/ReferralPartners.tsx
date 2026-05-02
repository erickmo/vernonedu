import { useState } from 'react'
import { Plus, Pencil, Eye } from 'lucide-react'
import { toast } from 'sonner'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import FormField from '@/components/shared/FormField'
import FormModal from '@/components/shared/FormModal'
import RoleGate from '@/components/shared/RoleGate'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import { COMMISSION_TYPES, type ReferralPartner } from '@/types/referralpartner'
import {
  useReferralPartners,
  useCreateReferralPartner,
  useUpdateReferralPartner,
  useReferrals,
} from '@/lib/api/marketing'

interface FormState {
  name: string
  contact_email: string
  referral_code: string
  commission_type: 'percent' | 'fixed'
  commission_value: number
  is_active?: boolean
}

const EMPTY: FormState = {
  name: '',
  contact_email: '',
  referral_code: '',
  commission_type: 'percent',
  commission_value: 10,
  is_active: true,
}

export default function ReferralPartners() {
  const [activeOnly, setActiveOnly] = useState(false)
  const { data, isLoading } = useReferralPartners({
    is_active: activeOnly ? true : undefined,
  })

  const [editing, setEditing] = useState<ReferralPartner | null>(null)
  const [open, setOpen] = useState(false)
  const [form, setForm] = useState<FormState>(EMPTY)
  const [refsForId, setRefsForId] = useState<string | null>(null)

  const create = useCreateReferralPartner()
  const update = useUpdateReferralPartner(editing?.id ?? '')

  function openCreate() {
    setEditing(null)
    setForm(EMPTY)
    setOpen(true)
  }
  function openEdit(p: ReferralPartner) {
    setEditing(p)
    setForm({
      name: p.name,
      contact_email: p.contact_email ?? '',
      referral_code: p.referral_code,
      commission_type: (p.commission_type as 'percent' | 'fixed') || 'percent',
      commission_value: p.commission_value,
      is_active: p.is_active,
    })
    setOpen(true)
  }

  async function onSubmit() {
    try {
      if (editing) {
        await update.mutateAsync({
          name: form.name,
          contact_email: form.contact_email,
          commission_type: form.commission_type,
          commission_value: form.commission_value,
          is_active: form.is_active,
        })
      } else {
        await create.mutateAsync({
          name: form.name,
          contact_email: form.contact_email,
          referral_code: form.referral_code,
          commission_type: form.commission_type,
          commission_value: form.commission_value,
        })
      }
      toast.success(editing ? 'Partner updated' : 'Partner created')
      setOpen(false)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed')
    }
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="Referral Partners"
        subtitle="External partners earning commission on referrals"
        actions={
          <RoleGate action="create" resource="referral_partner">
            <Button onClick={openCreate}>
              <Plus className="w-4 h-4" /> Add Partner
            </Button>
          </RoleGate>
        }
      />

      <label className="inline-flex items-center gap-2 text-sm text-neutral-700">
        <input
          type="checkbox"
          checked={activeOnly}
          onChange={(e) => setActiveOnly(e.target.checked)}
        />
        Active only
      </label>

      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <div className="bg-white rounded-xl border border-neutral-100 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 text-neutral-600">
              <tr>
                <th className="px-4 py-2.5 text-left">Name</th>
                <th className="px-4 py-2.5 text-left">Code</th>
                <th className="px-4 py-2.5 text-left">Commission</th>
                <th className="px-4 py-2.5 text-left">Status</th>
                <th className="px-4 py-2.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {(data ?? []).length === 0 && (
                <tr>
                  <td colSpan={5} className="px-4 py-6 text-center text-neutral-500">
                    No referral partners
                  </td>
                </tr>
              )}
              {(data ?? []).map((p) => (
                <tr key={p.id} className="border-t border-neutral-100">
                  <td className="px-4 py-2.5">
                    <div className="font-medium">{p.name}</div>
                    <div className="text-xs text-neutral-500">{p.contact_email}</div>
                  </td>
                  <td className="px-4 py-2.5 font-mono text-xs">{p.referral_code}</td>
                  <td className="px-4 py-2.5">
                    {p.commission_type === 'percent'
                      ? `${p.commission_value}%`
                      : `Rp ${p.commission_value.toLocaleString()}`}
                  </td>
                  <td className="px-4 py-2.5">
                    <span
                      className={`px-2 py-0.5 text-xs rounded-full ${
                        p.is_active
                          ? 'bg-green-100 text-green-700'
                          : 'bg-neutral-100 text-neutral-600'
                      }`}
                    >
                      {p.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="px-4 py-2.5 text-right">
                    <button
                      onClick={() => setRefsForId(p.id === refsForId ? null : p.id)}
                      className="p-1.5 text-neutral-500 hover:text-brand-600 mr-1"
                      aria-label="View referrals"
                    >
                      <Eye className="w-4 h-4" />
                    </button>
                    <RoleGate action="update" resource="referral_partner">
                      <button
                        onClick={() => openEdit(p)}
                        className="p-1.5 text-neutral-500 hover:text-brand-600"
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
        </div>
      )}

      {refsForId && <ReferralsBlock partnerId={refsForId} />}

      <FormModal
        open={open}
        onOpenChange={setOpen}
        title={editing ? 'Edit Partner' : 'New Partner'}
        onSubmit={onSubmit}
        loading={create.isPending || update.isPending}
      >
        <FormField label="Name" required>
          <Input
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
        </FormField>
        <FormField label="Contact Email">
          <Input
            type="email"
            value={form.contact_email}
            onChange={(e) => setForm({ ...form, contact_email: e.target.value })}
          />
        </FormField>
        {!editing && (
          <FormField label="Referral Code" required>
            <Input
              value={form.referral_code}
              onChange={(e) => setForm({ ...form, referral_code: e.target.value })}
              placeholder="e.g. ALPHA10"
            />
          </FormField>
        )}
        <FormField label="Commission Type" required>
          <Select
            value={form.commission_type}
            onChange={(e) =>
              setForm({ ...form, commission_type: e.target.value as 'percent' | 'fixed' })
            }
          >
            {COMMISSION_TYPES.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </Select>
        </FormField>
        <FormField label="Commission Value" required>
          <Input
            type="number"
            min={0}
            step="0.01"
            value={form.commission_value}
            onChange={(e) =>
              setForm({ ...form, commission_value: parseFloat(e.target.value || '0') })
            }
          />
        </FormField>
        {editing && (
          <label className="inline-flex items-center gap-2 text-sm text-neutral-700">
            <input
              type="checkbox"
              checked={form.is_active ?? false}
              onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
            />
            Active
          </label>
        )}
      </FormModal>
    </div>
  )
}

function ReferralsBlock({ partnerId }: { partnerId: string }) {
  const { data, isLoading } = useReferrals(partnerId)
  return (
    <div className="bg-white rounded-xl border border-neutral-100 p-4">
      <div className="text-sm font-semibold text-neutral-900 mb-3">Referrals</div>
      {isLoading ? (
        <div className="text-sm text-neutral-500">Loading...</div>
      ) : (data ?? []).length === 0 ? (
        <div className="text-sm text-neutral-500">No referrals yet</div>
      ) : (
        <table className="w-full text-sm">
          <thead className="text-neutral-500">
            <tr>
              <th className="text-left py-1.5">Student</th>
              <th className="text-left py-1.5">Course</th>
              <th className="text-left py-1.5">Commission</th>
              <th className="text-left py-1.5">Status</th>
            </tr>
          </thead>
          <tbody>
            {data!.map((r) => (
              <tr key={r.id} className="border-t border-neutral-100">
                <td className="py-1.5">{r.student_name}</td>
                <td className="py-1.5">{r.course_name}</td>
                <td className="py-1.5">Rp {r.commission_amount.toLocaleString()}</td>
                <td className="py-1.5">{r.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}
