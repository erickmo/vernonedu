import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  CoaAccount,
  CoaListResponse,
  CoaTreeNode,
  CreateCoaPayload,
  UpdateCoaPayload,
} from '@/types/coa'
import type {
  FinanceAccount,
  FinanceAccountListResponse,
  CreateFinanceAccountPayload,
  UpdateFinanceAccountPayload,
} from '@/types/financeaccount'

const COA_BASE = '/finance/coa'
const QK_COA = ['finance', 'coa'] as const

function buildCoaTree(flat: CoaAccount[]): CoaTreeNode[] {
  const map = new Map<string, CoaTreeNode>()
  flat.forEach((a) => map.set(a.id, { ...a, children: [] }))

  const roots: CoaTreeNode[] = []
  flat.forEach((a) => {
    const node = map.get(a.id)!
    if (a.parent_id && map.has(a.parent_id)) {
      map.get(a.parent_id)!.children!.push(node)
    } else {
      roots.push(node)
    }
  })
  return roots
}

export function useCoaAccounts(branchId?: string) {
  return useQuery({
    queryKey: [...QK_COA, 'list', branchId ?? null],
    queryFn: () =>
      apiClient
        .get<CoaListResponse>(COA_BASE, {
          params: branchId ? { branch_id: branchId } : undefined,
        })
        .then((r) => r.data.data ?? []),
  })
}

export function useCoaTree(branchId?: string) {
  return useQuery({
    queryKey: [...QK_COA, 'tree', branchId ?? null],
    queryFn: () =>
      apiClient
        .get<CoaListResponse>(COA_BASE, {
          params: branchId ? { branch_id: branchId } : undefined,
        })
        .then((r) => buildCoaTree(r.data.data ?? [])),
  })
}

export function useCoaAccount(id: string) {
  return useQuery({
    queryKey: [...QK_COA, 'detail', id],
    queryFn: () =>
      apiClient
        .get<{ data: CoaAccount }>(`${COA_BASE}/${id}`)
        .then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateCoaAccount() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: CreateCoaPayload) =>
      apiClient.post(COA_BASE, payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_COA }),
  })
}

export function useUpdateCoaAccount() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateCoaPayload }) =>
      apiClient.put(`${COA_BASE}/${id}`, payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_COA }),
  })
}

export function useFinanceAccounts(branchId?: string) {
  return useQuery({
    queryKey: ['finance', 'accounts', 'list', branchId ?? null],
    queryFn: () =>
      apiClient
        .get<FinanceAccountListResponse>(COA_BASE, {
          params: branchId ? { branch_id: branchId } : undefined,
        })
        .then((r) =>
          (r.data.data ?? []).filter(
            (a) => a.type === 'asset' && /^11/.test(a.code),
          ),
        ),
  })
}

export function useCreateFinanceAccount() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: CreateFinanceAccountPayload) =>
      apiClient.post(COA_BASE, payload).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: QK_COA })
      qc.invalidateQueries({ queryKey: ['finance', 'accounts'] })
    },
  })
}

export function useUpdateFinanceAccount() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({
      id,
      payload,
    }: {
      id: string
      payload: UpdateFinanceAccountPayload
    }) => apiClient.put(`${COA_BASE}/${id}`, payload).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: QK_COA })
      qc.invalidateQueries({ queryKey: ['finance', 'accounts'] })
    },
  })
}

export type { FinanceAccount }
