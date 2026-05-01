/**
 * DepartmentDetailPage
 * Detailed view of a department with leader assignment and statistics
 */

import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Users, BookOpen, Clock, CheckCircle } from 'lucide-react'
import { useDepartment, useStaff } from '@/lib/queries'
import {
  useUpdateDepartment,
  useDeleteDepartment,
} from '@/lib/mutations'
import { AssignLeaderValues } from '@/schemas/department'
import Button from '@/components/ui/Button'
import PageHeader from '@/components/shared/PageHeader'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import AssignLeaderDialog from '@/components/admin/AssignLeaderDialog'

export default function DepartmentDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()

  // Queries
  const { data: department, isLoading, error } = useDepartment(id)
  const { data: staff = [] } = useStaff()

  // Mutations
  const updateMutation = useUpdateDepartment()
  const deleteMutation = useDeleteDepartment()

  // Local state
  const [showAssignLeader, setShowAssignLeader] = useState(false)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  const handleAssignLeader = async (values: AssignLeaderValues) => {
    if (!id) return

    try {
      await updateMutation.mutateAsync({
        id,
        payload: {
          leader_id: values.leaderId,
        },
      })
    } catch (error) {
      console.error('Failed to assign leader:', error)
    }
  }

  const handleDeleteDepartment = async () => {
    if (!id) return

    try {
      await deleteMutation.mutateAsync(id)
      setShowDeleteDialog(false)
      navigate('/admin/departments')
    } catch (error) {
      console.error('Failed to delete department:', error)
    }
  }

  // Loading state
  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader title="Memuat..." />
        <div className="bg-white rounded-lg p-8 text-center text-neutral-500">
          Memuat detail departemen...
        </div>
      </div>
    )
  }

  // Error state
  if (error || !department) {
    return (
      <div className="space-y-6">
        <PageHeader title="Departemen" />
        <div className="rounded-lg bg-red-50 border border-red-200 p-4">
          <p className="text-sm text-red-700 mb-3">
            Gagal memuat departemen. Silakan coba lagi.
          </p>
          <Button
            variant="secondary"
            onClick={() => navigate('/admin/departments')}
          >
            Kembali ke Daftar
          </Button>
        </div>
      </div>
    )
  }

  // Get leader info
  const leaderInfo = staff.find((s) => s.id === department.leaderId)

  return (
    <div className="space-y-6">
      {/* Page Header with Back Button */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => navigate('/admin/departments')}
          className="p-2 hover:bg-neutral-100 rounded-lg transition-colors"
        >
          <ArrowLeft className="w-5 h-5 text-neutral-600" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">
            {department.name}
          </h1>
          <p className="mt-1 text-sm text-neutral-500">
            Detail departemen dan pengaturan
          </p>
        </div>
      </div>

      {/* Section 1: Department Info */}
      <div className="bg-white rounded-lg border border-neutral-200 p-6 space-y-4">
        <h2 className="text-lg font-semibold text-neutral-900">
          Informasi Departemen
        </h2>

        <div className="space-y-3">
          {/* Name */}
          <div className="grid grid-cols-3 gap-4">
            <div>
              <p className="text-xs font-medium text-neutral-500 uppercase">
                Nama Departemen
              </p>
              <p className="mt-1 text-sm text-neutral-900">
                {department.name}
              </p>
            </div>

            {/* Status */}
            <div>
              <p className="text-xs font-medium text-neutral-500 uppercase">
                Status
              </p>
              <div className="mt-1">
                <span
                  className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-medium ${
                    department.isActive
                      ? 'bg-green-50 text-green-700'
                      : 'bg-red-50 text-red-700'
                  }`}
                >
                  <span className="w-1.5 h-1.5 rounded-full bg-current" />
                  {department.isActive ? 'Aktif' : 'Tidak Aktif'}
                </span>
              </div>
            </div>
          </div>

          {/* Description */}
          {department.description && (
            <div>
              <p className="text-xs font-medium text-neutral-500 uppercase">
                Deskripsi
              </p>
              <p className="mt-1 text-sm text-neutral-700 leading-relaxed">
                {department.description}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Section 2: Leader Assignment */}
      <div className="bg-white rounded-lg border border-neutral-200 p-6 space-y-4">
        <h2 className="text-lg font-semibold text-neutral-900">
          Kepala Departemen
        </h2>

        {leaderInfo ? (
          <div className="flex items-center gap-4 p-4 bg-neutral-50 rounded-lg">
            <div className="w-12 h-12 rounded-full bg-brand-100 flex items-center justify-center text-brand-600 font-semibold">
              {leaderInfo.name.charAt(0).toUpperCase()}
            </div>
            <div className="flex-1">
              <p className="font-medium text-neutral-900">{leaderInfo.name}</p>
              <p className="text-sm text-neutral-500">{leaderInfo.role}</p>
            </div>
          </div>
        ) : (
          <div className="p-4 bg-neutral-50 rounded-lg">
            <p className="text-sm text-neutral-500">
              Belum ada kepala departemen yang ditunjuk
            </p>
          </div>
        )}

        <Button
          variant="secondary"
          onClick={() => setShowAssignLeader(true)}
          className="w-full"
        >
          Ubah Kepala Departemen
        </Button>
      </div>

      {/* Section 3: Statistics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Courses */}
        <div className="bg-white rounded-lg border border-neutral-200 p-4">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center">
              <BookOpen className="w-4 h-4 text-blue-600" />
            </div>
            <span className="text-xs font-medium text-neutral-500 uppercase">
              Kursus
            </span>
          </div>
          <p className="text-2xl font-bold text-neutral-900">
            {department.courseCount || 0}
          </p>
        </div>

        {/* Paid Enrollments */}
        <div className="bg-white rounded-lg border border-neutral-200 p-4">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-8 h-8 rounded-lg bg-green-50 flex items-center justify-center">
              <Users className="w-4 h-4 text-green-600" />
            </div>
            <span className="text-xs font-medium text-neutral-500 uppercase">
              Siswa (Dibayar)
            </span>
          </div>
          <p className="text-2xl font-bold text-neutral-900">
            {department.paidEnrollmentCount || 0}
          </p>
        </div>

        {/* Ongoing Batches */}
        <div className="bg-white rounded-lg border border-neutral-200 p-4">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-8 h-8 rounded-lg bg-purple-50 flex items-center justify-center">
              <Clock className="w-4 h-4 text-purple-600" />
            </div>
            <span className="text-xs font-medium text-neutral-500 uppercase">
              Berlangsung
            </span>
          </div>
          <p className="text-2xl font-bold text-neutral-900">
            {department.batchOngoing || 0}
          </p>
        </div>

        {/* Completed Batches */}
        <div className="bg-white rounded-lg border border-neutral-200 p-4">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-8 h-8 rounded-lg bg-orange-50 flex items-center justify-center">
              <CheckCircle className="w-4 h-4 text-orange-600" />
            </div>
            <span className="text-xs font-medium text-neutral-500 uppercase">
              Selesai
            </span>
          </div>
          <p className="text-2xl font-bold text-neutral-900">
            {department.batchCompleted || 0}
          </p>
        </div>
      </div>

      {/* Section 4: Dangerous Actions */}
      <div className="bg-red-50 rounded-lg border border-red-200 p-6 space-y-4">
        <h2 className="text-lg font-semibold text-red-600">
          Tindakan Berbahaya
        </h2>
        <p className="text-sm text-red-700">
          Tindakan di bawah tidak dapat dibatalkan. Lakukan dengan hati-hati.
        </p>

        <Button
          variant="danger"
          onClick={() => setShowDeleteDialog(true)}
          loading={deleteMutation.isPending}
          disabled={deleteMutation.isPending}
          className="w-full"
        >
          Hapus Departemen
        </Button>
      </div>

      {/* Dialogs */}
      <AssignLeaderDialog
        open={showAssignLeader}
        staff={staff}
        currentLeaderId={department.leaderId}
        loading={updateMutation.isPending}
        onSubmit={handleAssignLeader}
        onOpenChange={setShowAssignLeader}
      />

      <ConfirmDialog
        open={showDeleteDialog}
        onConfirm={handleDeleteDepartment}
        onCancel={() => setShowDeleteDialog(false)}
        title="Hapus Departemen"
        description={`Apakah Anda yakin ingin menghapus departemen "${department.name}"? Tindakan ini tidak dapat dibatalkan.`}
        confirmLabel="Hapus"
        destructive
      />
    </div>
  )
}
