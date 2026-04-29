import { ReactNode } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import EmptyState from './EmptyState'

export interface Column<T> {
  header: string
  accessor: keyof T | string
  cell?: (row: T) => ReactNode
  className?: string
}

interface Pagination {
  page: number
  limit: number
  total: number
}

interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  loading?: boolean
  pagination?: Pagination
  onPageChange?: (page: number) => void
  rowKey?: (row: T) => string
  onRowClick?: (row: T) => void
}

function SkeletonRow({ cols }: { cols: number }) {
  return (
    <tr>
      {Array.from({ length: cols }).map((_, i) => (
        <td key={i} className="px-4 py-3">
          <div className="h-4 bg-neutral-200 rounded animate-pulse" />
        </td>
      ))}
    </tr>
  )
}

function getCellValue<T>(row: T, accessor: keyof T | string): ReactNode {
  const val = (row as Record<string, unknown>)[accessor as string]
  if (val === null || val === undefined) return '—'
  return String(val)
}

export default function DataTable<T>({
  columns,
  data,
  loading = false,
  pagination,
  onPageChange,
  rowKey,
  onRowClick,
}: DataTableProps<T>) {
  const totalPages = pagination ? Math.ceil(pagination.total / pagination.limit) : 1
  const currentPage = pagination?.page ?? 1

  if (!loading && data.length === 0) {
    return (
      <div className="rounded-lg border border-border">
        <EmptyState title="No records found" description="There are no items to display." />
      </div>
    )
  }

  return (
    <div className="rounded-lg border border-border overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-neutral-50 border-b border-border">
            <tr>
              {columns.map((col) => (
                <th
                  key={String(col.accessor)}
                  className={cn(
                    'px-4 py-3 text-left text-xs font-semibold text-neutral-500 uppercase tracking-wider',
                    col.className
                  )}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-border bg-white">
            {loading
              ? Array.from({ length: 5 }).map((_, i) => <SkeletonRow key={i} cols={columns.length} />)
              : data.map((row, idx) => (
                  <tr
                    key={rowKey ? rowKey(row) : idx}
                    onClick={() => onRowClick?.(row)}
                    className={cn(
                      'hover:bg-neutral-50 transition-colors',
                      onRowClick && 'cursor-pointer',
                    )}
                  >
                    {columns.map((col) => (
                      <td
                        key={String(col.accessor)}
                        className={cn('px-4 py-3 text-neutral-700', col.className)}
                      >
                        {col.cell ? col.cell(row) : getCellValue(row, col.accessor)}
                      </td>
                    ))}
                  </tr>
                ))}
          </tbody>
        </table>
      </div>

      {pagination && totalPages > 1 && (
        <div className="flex items-center justify-between px-4 py-3 border-t border-border bg-neutral-50">
          <p className="text-xs text-neutral-500">
            Showing {(currentPage - 1) * pagination.limit + 1}–
            {Math.min(currentPage * pagination.limit, pagination.total)} of {pagination.total}
          </p>
          <div className="flex items-center gap-1">
            <button
              onClick={() => onPageChange?.(currentPage - 1)}
              disabled={currentPage <= 1}
              className="p-1.5 rounded hover:bg-neutral-200 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="text-xs font-medium px-2">
              {currentPage} / {totalPages}
            </span>
            <button
              onClick={() => onPageChange?.(currentPage + 1)}
              disabled={currentPage >= totalPages}
              className="p-1.5 rounded hover:bg-neutral-200 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
