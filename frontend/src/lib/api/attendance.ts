import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { AttendanceRecord, AttendanceMark, SessionSummary } from '@/types/attendance'

interface ListResponseEnvelope<T> {
  data: T[]
}

interface SingleResponse<T> {
  data: T
}

export function useSessionAttendance(batchId: string | undefined, sessionId: string | undefined) {
  return useQuery({
    queryKey: ['attendance', batchId, sessionId],
    queryFn: () =>
      apiClient
        .get<ListResponseEnvelope<AttendanceRecord>>(
          `/course-batches/${batchId}/sessions/${sessionId}/attendance`,
        )
        .then((r) => r.data.data),
    enabled: !!batchId && !!sessionId,
  })
}

export function useSubmitAttendance(batchId: string, sessionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (marks: AttendanceMark[]) =>
      apiClient
        .post(
          `/course-batches/${batchId}/sessions/${sessionId}/attendance`,
          { marks },
        )
        .then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['attendance', batchId, sessionId] })
      qc.invalidateQueries({ queryKey: ['batch-sessions', batchId] })
    },
  })
}

export function useMySessions(from: string, to: string) {
  return useQuery({
    queryKey: ['my-sessions', from, to],
    queryFn: () =>
      apiClient
        .get<ListResponseEnvelope<SessionSummary>>('/sessions/my', {
          params: { from, to },
        })
        .then((r) => r.data.data),
    enabled: !!from && !!to,
  })
}

export function useBatchSessions(batchId: string | undefined) {
  return useQuery({
    queryKey: ['batch-sessions', batchId],
    queryFn: () =>
      apiClient
        .get<ListResponseEnvelope<SessionSummary> | SingleResponse<SessionSummary[]>>(
          `/course-batches/${batchId}/sessions`,
        )
        .then((r) => {
          const body = r.data as { data: SessionSummary[] | SessionSummary }
          return Array.isArray(body.data) ? body.data : []
        }),
    enabled: !!batchId,
  })
}
