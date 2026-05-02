import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ClipboardList, Save, ArrowLeft } from 'lucide-react'
import { toast } from 'sonner'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import { useSessionAttendance, useSubmitAttendance } from '@/lib/api/attendance'
import {
  ATTENDANCE_STATUSES,
  ATTENDANCE_STATUS_LABELS,
} from '@/schemas/attendance'
import type { AttendanceStatus, AttendanceRecord } from '@/types/attendance'

type MarksMap = Record<string, { status: AttendanceStatus; note?: string }>

function buildInitialMarks(records: AttendanceRecord[] | undefined): MarksMap {
  const map: MarksMap = {}
  if (!records) return map
  for (const r of records) {
    map[r.student_id] = { status: r.status, note: r.note }
  }
  return map
}

export default function AttendancePage() {
  const { id: batchId = '', sessionId = '' } = useParams<{
    id: string
    sessionId: string
  }>()
  const navigate = useNavigate()
  const { data: records, isLoading } = useSessionAttendance(batchId, sessionId)
  const submit = useSubmitAttendance(batchId, sessionId)
  const [marks, setMarks] = useState<MarksMap>({})

  useEffect(() => {
    if (records) setMarks(buildInitialMarks(records))
  }, [records])

  const totals = useMemo(() => {
    const t = { present: 0, late: 0, absent: 0, excused: 0 }
    for (const id in marks) t[marks[id].status]++
    return t
  }, [marks])

  function setStatus(studentId: string, status: AttendanceStatus) {
    setMarks((prev) => ({
      ...prev,
      [studentId]: { ...(prev[studentId] ?? {}), status },
    }))
  }

  async function onSave() {
    if (!records || records.length === 0) {
      toast.error('No students to mark')
      return
    }
    const payload = records.map((r) => ({
      student_id: r.student_id,
      status: marks[r.student_id]?.status ?? 'absent',
      note: marks[r.student_id]?.note,
    }))
    try {
      await submit.mutateAsync(payload)
      toast.success('Attendance saved')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to save attendance')
    }
  }

  if (isLoading) return <LoadingSpinner size="lg" />

  return (
    <div>
      <PageHeader
        title="Take Attendance"
        subtitle={`Session ${sessionId.slice(0, 8)}`}
        breadcrumbs={[
          { label: 'Batches', href: '/internal/batches' },
          { label: 'Detail', href: `/internal/batches/${batchId}` },
          { label: 'Attendance' },
        ]}
        actions={
          <>
            <Button variant="ghost" onClick={() => navigate(`/internal/batches/${batchId}`)}>
              <ArrowLeft className="w-4 h-4" /> Back
            </Button>
            <Button onClick={onSave} disabled={submit.isPending}>
              <Save className="w-4 h-4" />
              {submit.isPending ? 'Saving…' : 'Save All'}
            </Button>
          </>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 p-4 mb-4 flex items-center gap-4 text-sm">
        <ClipboardList className="w-5 h-5 text-brand-600" />
        {ATTENDANCE_STATUSES.map((s) => (
          <span key={s} className="text-neutral-700">
            <span className="font-semibold">{totals[s]}</span>{' '}
            <span className="text-neutral-500">{ATTENDANCE_STATUS_LABELS[s]}</span>
          </span>
        ))}
      </div>

      {!records || records.length === 0 ? (
        <p className="text-sm text-neutral-400">No students enrolled in this session.</p>
      ) : (
        <div className="bg-white rounded-xl border border-neutral-100 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 text-xs text-neutral-500 uppercase">
              <tr>
                <th className="text-left px-4 py-2 font-semibold">Student</th>
                <th className="text-left px-4 py-2 font-semibold">Code</th>
                <th className="text-left px-4 py-2 font-semibold">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {records.map((r) => (
                <tr key={r.student_id}>
                  <td className="px-4 py-3 text-neutral-800">{r.student_name}</td>
                  <td className="px-4 py-3 font-mono text-xs text-neutral-500">
                    {r.student_code ?? '—'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="inline-flex rounded-lg border border-neutral-200 overflow-hidden">
                      {ATTENDANCE_STATUSES.map((s) => {
                        const active = (marks[r.student_id]?.status ?? r.status) === s
                        return (
                          <button
                            key={s}
                            type="button"
                            onClick={() => setStatus(r.student_id, s)}
                            className={
                              'px-3 py-1.5 text-xs font-medium border-r last:border-r-0 border-neutral-200 transition-colors ' +
                              (active
                                ? 'bg-brand-600 text-white'
                                : 'bg-white text-neutral-600 hover:bg-neutral-50')
                            }
                          >
                            {ATTENDANCE_STATUS_LABELS[s]}
                          </button>
                        )
                      })}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
