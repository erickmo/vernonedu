/**
 * DepartmentListPage
 * Full page for listing departments with search, filtering, and bulk actions
 */

import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, Plus } from 'lucide-react'
import { useDepartments } from '@/lib/queries'
import { useDeleteDepartment } from '@/lib/mutations'
import { Department } from '@/types/department'
import PageHeader from '@/components/shared/PageHeader'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import DepartmentTable from '@/components/admin/DepartmentTable'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'

export default function DepartmentListPage() {
  const navigate = useNavigate()

  // Queries
  const { data: departments = [], isLoading, error } = useDepartments()
  const deleteAware = useDeleteDepartment()

  // Local state
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedDept, setSelectedDept] = useState<Department | null>(null)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  // Filter departments by search query
  const filteredDepartments = useMemo(() => {
    if (!searchQuery.trim()) return departments

    const query = searchQuery.toLowerCase()
    return departments.filter(
      (dept) =>
        dept.name.toLowerCase().includes(query) ||
        dept.leaderName?.toLowerCase().includes(query)
    )
  }, [departments, searchQuery])

  // Handlers
  const handleEdit = (dept: Department) => {
    navigate(`/admin/departments/${dept.id}`)
  }

  const handleDelete = (dept: Department) => {
    setSelectedDept(dept)
    setShowDeleteDialog(true)
  }

  const handleConfirmDelete = async () => {
    if (!selectedDept) return

    try {
      await deleteAware.mutateAsync(selectedDept.id)
      setShowDeleteDialog(false)
      setSelectedDept(null)
    } catch (err) {
      console.error('Delete failed:', err)
    }
  }

  const handleCancelDelete = () => {
    setShowDeleteDialog(false)
    setSelectedDept(null)
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title="Departemen"
        subtitle="Kelola departemen dan lihat ringkasan aktivitas"
        actions={
          <Button
            variant="primary"
            size="md"
            onClick={() => navigate('/admin/departments/new')}
            className="flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            Tambah Departemen
          </Button>
        }
      />

      {/* Error Banner */}
      {error && (
        <div className="rounded-lg bg-red-50 border border-red-200 p-4">
          <p className="text-sm text-red-700">
            Gagal memuat departemen. Silakan coba lagi.
          </p>
        </div>
      )}

      {/* Search Section */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-neutral-400" />
        <Input
          placeholder="Cari departemen..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Results Count */}
      {!isLoading && filteredDepartments.length > 0 && (
        <div className="text-xs text-neutral-500">
          Menampilkan {filteredDepartments.length} dari {departments.length} departemen
        </div>
      )}

      {/* Table Component */}
      <DepartmentTable
        departments={filteredDepartments}
        loading={isLoading}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={showDeleteDialog}
        onConfirm={handleConfirmDelete}
        onCancel={handleCancelDelete}
        title="Hapus Departemen"
        description={`Apakah Anda yakin ingin menghapus departemen "${selectedDept?.name}"? Tindakan ini tidak dapat dibatalkan.`}
        confirmLabel="Hapus"
        destructive
      />
    </div>
  )
}
