/**
 * DepartmentCreatePage
 * Page for creating a new department
 */

import { useNavigate } from 'react-router-dom'
import { useStaff } from '@/lib/queries'
import { useCreateDepartment } from '@/lib/mutations'
import DepartmentForm from '@/components/admin/DepartmentForm'
import type { DepartmentFormValues } from '@/schemas/department'

export default function DepartmentCreatePage() {
  const navigate = useNavigate()
  const { data: staff = [], isLoading: staffLoading } = useStaff()
  const createMutation = useCreateDepartment()

  const handleSubmit = async (values: DepartmentFormValues) => {
    try {
      const result = await createMutation.mutateAsync({
        name: values.name,
        description: values.description || '',
        leader_id: values.leaderId,
        is_active: true,
      })
      navigate(`/admin/departments/${result.id}`)
    } catch (error) {
      console.error('Failed to create department:', error)
    }
  }

  const handleCancel = () => {
    navigate('/admin/departments')
  }

  return (
    <div className="max-w-2xl">
      {/* Page Header */}
      <h1 className="text-3xl font-bold text-gray-900 mb-2">
        Buat Departemen Baru
      </h1>
      <p className="text-gray-600 mb-8">
        Tambahkan departemen baru dan tetapkan kepala departemennya
      </p>

      {/* Form Card */}
      <div className="bg-white rounded-lg border border-gray-200 p-8">
        {staffLoading ? (
          <p className="text-gray-500">Memuat data staff...</p>
        ) : (
          <DepartmentForm
            staff={staff}
            loading={createMutation.isPending}
            onSubmit={handleSubmit}
            onCancel={handleCancel}
          />
        )}
      </div>
    </div>
  )
}
