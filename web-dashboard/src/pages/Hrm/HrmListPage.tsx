import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { hrmService } from '@/services/hrm.service'
import { EMPLOYEE_STATUS_LABELS, EMPLOYEE_STATUS_COLORS } from '@/types/hrm.types'
import type { Employee, EmployeeStatus } from '@/types/hrm.types'

const columns: ColumnDef<Employee>[] = [
  {
    key: 'employee_number',
    header: 'No. Karyawan',
    sortable: true,
    width: 130,
    render: (_v, row) => (
      <span style={{ fontWeight: 600, fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
        {row.employee_number || '—'}
      </span>
    ),
  },
  {
    key: 'user_name',
    header: 'Nama',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 'var(--radius-full)',
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0, fontWeight: 700,
          fontSize: 'var(--font-sm)',
        }}>
          {(row.user_name || '?').charAt(0).toUpperCase()}
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
            {row.user_name || '—'}
          </div>
          {row.user_email && (
            <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-xs)', marginTop: 1 }}>
              {row.user_email}
            </div>
          )}
        </div>
      </div>
    ),
  },
  {
    key: 'department_name',
    header: 'Departemen',
    sortable: true,
    width: 150,
    render: (_v, row) => row.department_name || '—',
  },
  {
    key: 'position',
    header: 'Jabatan',
    sortable: true,
    width: 150,
  },
  {
    key: 'status',
    header: 'Status',
    width: 110,
    align: 'center',
    render: (_v, row) => {
      const s = row.status as EmployeeStatus
      const colors = EMPLOYEE_STATUS_COLORS[s]
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: colors?.bg ?? 'var(--color-surface-alt)',
          color: colors?.color ?? 'var(--color-text-tertiary)',
        }}>
          {EMPLOYEE_STATUS_LABELS[s] ?? s}
        </span>
      )
    },
  },
  {
    key: 'hire_date',
    header: 'Tanggal Masuk',
    sortable: true,
    width: 130,
    render: (_v, row) => {
      if (!row.hire_date) return '—'
      return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric',
      }).format(new Date(row.hire_date))
    },
  },
]

const filterDefs: FilterDef[] = [
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: Object.entries(EMPLOYEE_STATUS_LABELS).map(([value, label]) => ({ label, value })),
  },
]

export default function HrmListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Employee>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/hrm/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Employee>
        title="Karyawan"
        addLabel="Tambah Karyawan"
        onAdd={() => navigate('/hrm/new')}
        queryKey="hrm-employees"
        fetcher={(params) => hrmService.listEmployees(params)}
        columns={columns}
        rowActions={rowActions}
        onRowClick={(row) => navigate(`/hrm/${row.id}`)}
        searchPlaceholder="Cari karyawan..."
        exportFilename="karyawan"
        filterDefs={filterDefs}
        emptyTitle="Belum ada karyawan"
        emptyDescription="Tambahkan karyawan pertama untuk mulai mengelola SDM."
        helpTitle="Karyawan"
        helpText="Kelola data karyawan termasuk informasi pribadi, jabatan, departemen, dan status kepegawaian."
      />
  )
}
