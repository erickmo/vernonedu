import { useState } from 'react'
import { toast } from 'sonner'
import Button from '@/components/ui/Button'
import { useGrantAppAccess, useRevokeAppAccess } from '@/lib/api/enrollment'

interface Props {
  enrollmentId: string
  // Optional initial state hint; the component is otherwise stateless and
  // delegates final truth to the backend response.
  initialState?: 'granted' | 'revoked' | 'unknown'
}

// AppAccessActions — grant/revoke the student's supporting-app access for
// the given enrollment. Revoke prompts for confirmation.
export default function AppAccessActions({ enrollmentId, initialState = 'unknown' }: Props) {
  const [state, setState] = useState<'granted' | 'revoked' | 'unknown'>(initialState)
  const grant = useGrantAppAccess()
  const revoke = useRevokeAppAccess()

  async function onGrant() {
    try {
      await grant.mutateAsync(enrollmentId)
      setState('granted')
      toast.success('App access granted')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to grant access')
    }
  }

  async function onRevoke() {
    if (!window.confirm('Revoke supporting-app access for this enrollment?')) return
    try {
      await revoke.mutateAsync(enrollmentId)
      setState('revoked')
      toast.success('App access revoked')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to revoke access')
    }
  }

  return (
    <div className="flex items-center gap-2">
      <Button
        type="button"
        variant="primary"
        onClick={onGrant}
        loading={grant.isPending}
        disabled={grant.isPending || revoke.isPending || state === 'granted'}
      >
        Grant Access
      </Button>
      <Button
        type="button"
        variant="secondary"
        onClick={onRevoke}
        loading={revoke.isPending}
        disabled={grant.isPending || revoke.isPending || state === 'revoked'}
      >
        Revoke Access
      </Button>
      {state !== 'unknown' && (
        <span className="text-xs text-neutral-500">Last action: {state}</span>
      )}
    </div>
  )
}
