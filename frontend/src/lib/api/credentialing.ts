import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Certificate {
  id: string
  cert_number: string
  student_id: string
  student_name: string
  enrollment_id: string
  course_name: string
  cert_type_id: string
  issued_at: string
  expires_at?: string
  status: 'valid' | 'revoked' | 'expired'
  revoked_at?: string
  revoke_reason?: string
}

export interface CertificateType {
  id: string
  name: string
  template_url: string
  validity_months?: number
}

export interface VerifyCertificateResult {
  valid: boolean
  certificate?: Certificate
  message: string
}

// ── Certificate hooks ──────────────────────────────────────────────────────

export function useCertificates(studentId?: string) {
  return useQuery({
    queryKey: ['certificates', { studentId }],
    queryFn: () =>
      apiClient
        .get<Certificate[]>('/certificates', { params: studentId ? { student_id: studentId } : {} })
        .then((r) => r.data),
  })
}

export function useIssueCertificate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: { enrollment_id: string; cert_type_id: string }) =>
      apiClient.post<Certificate>('/certificates', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['certificates'] }),
  })
}

export function useRevokeCertificate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      apiClient.post<Certificate>(`/certificates/${id}/revoke`, { reason }).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['certificates'] }),
  })
}

export function useVerifyCertificate(certNumber: string) {
  return useQuery({
    queryKey: ['certificates', 'verify', certNumber],
    queryFn: () =>
      apiClient.get<VerifyCertificateResult>(`/certificates/verify/${certNumber}`).then((r) => r.data),
    enabled: !!certNumber,
  })
}

// ── Certificate type hooks ─────────────────────────────────────────────────

export function useCertificateTypes() {
  return useQuery({
    queryKey: ['certificate-types'],
    queryFn: () => apiClient.get<CertificateType[]>('/certificate-types').then((r) => r.data),
  })
}

export function useCreateCertificateType() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<CertificateType, 'id'>) =>
      apiClient.post<CertificateType>('/certificate-types', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['certificate-types'] }),
  })
}
