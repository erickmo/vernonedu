/**
 * DepartmentTable Component
 * Reusable table component for displaying departments with inline actions
 * Columns: Name | Leader | Status | Courses | Actions
 */

import { MoreVertical } from 'lucide-react'
import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import { Department } from '@/types/department'
import AvatarInitial from '@/components/shared/AvatarInitial'
import { cn } from '@/lib/utils/cn'

const SKELETON_ROWS = 5

interface DepartmentTableProps {
  departments: Department[]
  loading?: boolean
  onEdit: (dept: Department) => void
  onDelete: (dept: Department) => void
}

export default function DepartmentTable({
  departments,
  loading = false,
  onEdit,
  onDelete,
}: DepartmentTableProps) {
  return (
    <div className="overflow-x-auto rounded-lg border border-neutral-200">
      <table className="w-full">
        <thead>
          <tr className="bg-neutral-50 border-b border-neutral-200">
            <th className="px-6 py-3 text-left text-xs font-semibold text-neutral-700 uppercase tracking-wider">
              Nama Departemen
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-neutral-700 uppercase tracking-wider">
              Kepala Departemen
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-neutral-700 uppercase tracking-wider">
              Status
            </th>
            <th className="px-6 py-3 text-left text-xs font-semibold text-neutral-700 uppercase tracking-wider">
              Kursus
            </th>
            <th className="px-6 py-3 text-right text-xs font-semibold text-neutral-700 uppercase tracking-wider">
              Aksi
            </th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
            // Skeleton loaders
            Array.from({ length: SKELETON_ROWS }).map((_, idx) => (
              <tr key={`skeleton-${idx}`} className="border-b border-neutral-100 hover:bg-neutral-50">
                <td className="px-6 py-4">
                  <div className="h-4 bg-neutral-200 rounded w-32 animate-pulse" />
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <div className="h-8 w-8 bg-neutral-200 rounded-full animate-pulse" />
                    <div className="h-4 bg-neutral-200 rounded w-24 animate-pulse" />
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="h-6 bg-neutral-200 rounded w-16 animate-pulse" />
                </td>
                <td className="px-6 py-4">
                  <div className="h-4 bg-neutral-200 rounded w-8 animate-pulse" />
                </td>
                <td className="px-6 py-4 text-right">
                  <div className="h-8 w-8 bg-neutral-200 rounded animate-pulse ml-auto" />
                </td>
              </tr>
            ))
          ) : departments.length === 0 ? (
            // Empty state
            <tr>
              <td colSpan={5} className="px-6 py-12 text-center">
                <div className="space-y-2">
                  <p className="text-sm font-medium text-neutral-600">
                    Belum ada departemen
                  </p>
                  <p className="text-xs text-neutral-500">
                    Buat yang pertama untuk memulai
                  </p>
                </div>
              </td>
            </tr>
          ) : (
            // Data rows
            departments.map((dept) => (
              <tr key={dept.id} className="border-b border-neutral-100 hover:bg-neutral-50 transition-colors">
                {/* Department Name */}
                <td className="px-6 py-4 text-sm font-medium text-neutral-900">
                  {dept.name}
                </td>

                {/* Leader */}
                <td className="px-6 py-4 text-sm text-neutral-700">
                  {dept.leaderName ? (
                    <div className="flex items-center gap-2">
                      <AvatarInitial name={dept.leaderName} size="sm" />
                      <span className="truncate">{dept.leaderName}</span>
                    </div>
                  ) : (
                    <span className="text-neutral-400">—</span>
                  )}
                </td>

                {/* Status */}
                <td className="px-6 py-4">
                  <span
                    className={cn(
                      'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium',
                      dept.isActive
                        ? 'bg-green-50 text-green-700'
                        : 'bg-neutral-100 text-neutral-700'
                    )}
                  >
                    <span
                      className={cn(
                        'w-1.5 h-1.5 rounded-full',
                        dept.isActive ? 'bg-green-600' : 'bg-neutral-400'
                      )}
                    />
                    {dept.isActive ? 'Aktif' : 'Tidak Aktif'}
                  </span>
                </td>

                {/* Course Count */}
                <td className="px-6 py-4 text-sm text-neutral-700">
                  {dept.courseCount ?? 0}
                </td>

                {/* Actions */}
                <td className="px-6 py-4 text-right">
                  <DepartmentRowActions
                    dept={dept}
                    onEdit={onEdit}
                    onDelete={onDelete}
                  />
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  )
}

// ── Row Actions Menu ───────────────────────────────────────────────────────

interface DepartmentRowActionsProps {
  dept: Department
  onEdit: (dept: Department) => void
  onDelete: (dept: Department) => void
}

function DepartmentRowActions({
  dept,
  onEdit,
  onDelete,
}: DepartmentRowActionsProps) {
  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger asChild>
        <button
          className="inline-flex items-center justify-center w-8 h-8 text-neutral-500 rounded-lg hover:bg-neutral-100 transition-colors"
          aria-label="Department actions"
        >
          <MoreVertical className="w-4 h-4" />
        </button>
      </DropdownMenu.Trigger>

      <DropdownMenu.Portal>
        <DropdownMenu.Content
          className="min-w-[160px] bg-white rounded-lg shadow-lg border border-neutral-200 z-40"
          align="end"
          sideOffset={8}
        >
          <DropdownMenu.Item asChild>
            <button
              onClick={() => onEdit(dept)}
              className="w-full text-left px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50 transition-colors"
            >
              Edit
            </button>
          </DropdownMenu.Item>

          <DropdownMenu.Item asChild>
            <button
              onClick={() => onDelete(dept)}
              className="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition-colors"
            >
              Hapus
            </button>
          </DropdownMenu.Item>
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  )
}
