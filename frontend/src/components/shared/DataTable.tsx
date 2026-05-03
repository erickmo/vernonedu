import { ReactNode, useState, useMemo } from 'react'
import { ChevronLeft, ChevronRight, ArrowUpDown, ChevronUp, ChevronDown } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import EmptyState from './EmptyState'
import Skeleton from '@/components/ui/Skeleton'

export interface Column<T> {
  header: string
  accessor: keyof T | string
  cell?: (row: T) => ReactNode
  className?: string
  sortable?: boolean
}

type SortDirection = 'asc' | 'desc' | 'none'

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
  selectable?: boolean
  onSelectionChange?: (selectedRows: T[]) => void
}

function getCellValue<T>(row: T, accessor: keyof T | string): ReactNode {
  const val = (row as Record<string, unknown>)[accessor as string]
  if (val === null || val === undefined) return '—'
  return String(val)
}

function SkeletonRow({ cols }: { cols: number }) {
  return (
    <tr>
      {Array.from({ length: cols }).map((_, i) => (
        <td key={i} className="px-4 py-3">
          <Skeleton className="h-4 w-full" />
        </td>
      ))}
    </tr>
  )
}

export default function DataTable<T>({
  columns,
  data,
  loading = false,
  pagination,
  onPageChange,
  rowKey,
  onRowClick,
  selectable = false,
  onSelectionChange,
}: DataTableProps<T>) {
  const [sortColumn, setSortColumn] = useState<string | null>(null)
  const [sortDirection, setSortDirection] = useState<SortDirection>('none')
  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set())

  const totalPages = pagination ? Math.ceil(pagination.total / pagination.limit) : 1
  const currentPage = pagination?.page ?? 1

  const sortedData = useMemo(() => {
    if (!sortColumn || sortDirection === 'none') return data

    return [...data].sort((a, b) => {
      const aVal = (a as Record<string, unknown>)[sortColumn]
      const bVal = (b as Record<string, unknown>)[sortColumn]

      if (aVal === bVal) return 0
      if (aVal === null || aVal === undefined) return 1
      if (bVal === null || bVal === undefined) return -1

      const comparison = String(aVal).localeCompare(String(bVal))
      return sortDirection === 'asc' ? comparison : -comparison
    })
  }, [data, sortColumn, sortDirection])

  const handleSort = (accessor: string) => {
    if (sortColumn === accessor) {
      if (sortDirection === 'asc') {
        setSortDirection('desc')
      } else if (sortDirection === 'desc') {
        setSortDirection('none')
        setSortColumn(null)
      }
    } else {
      setSortColumn(accessor)
      setSortDirection('asc')
    }
  }

  const getSortIcon = (col: Column<T>) => {
    if (!col.sortable) return null

    const isSorted = sortColumn === String(col.accessor)

    if (!isSorted) {
      return <ArrowUpDown className="w-3 h-3 text-neutral-400 inline ml-1" />
    }

    if (sortDirection === 'asc') {
      return <ChevronUp className="w-3 h-3 text-neutral-600 inline ml-1" />
    }

    return <ChevronDown className="w-3 h-3 text-neutral-600 inline ml-1" />
  }

  const handleSelectRow = (row: T) => {
    const key = rowKey ? rowKey(row) : JSON.stringify(row)
    const newSelection = new Set(selectedRows)

    if (newSelection.has(key)) {
      newSelection.delete(key)
    } else {
      newSelection.add(key)
    }

    setSelectedRows(newSelection)

    if (onSelectionChange) {
      const selected = sortedData.filter(r => {
        const rKey = rowKey ? rowKey(r) : JSON.stringify(r)
        return newSelection.has(rKey)
      })
      onSelectionChange(selected)
    }
  }

  const handleSelectAll = () => {
    if (selectedRows.size === sortedData.length) {
      setSelectedRows(new Set())
      onSelectionChange?.([])
    } else {
      const allKeys = sortedData.map(r => rowKey ? rowKey(r) : JSON.stringify(r))
      setSelectedRows(new Set(allKeys))
      onSelectionChange?.([...sortedData])
    }
  }

  const allSelected = sortedData.length > 0 && selectedRows.size === sortedData.length
  const someSelected = selectedRows.size > 0 && !allSelected

  const displayColumns = selectable ? [{ header: '', accessor: '_checkbox' } as Column<T>, ...columns] : columns

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
              {displayColumns.map((col) => {
                const isCheckboxCol = col.accessor === '_checkbox'

                return (
                  <th
                    key={String(col.accessor)}
                    className={cn(
                      'px-4 py-3 text-left text-xs font-semibold text-neutral-500 uppercase tracking-wider',
                      !isCheckboxCol && col.className,
                      col.sortable && !isCheckboxCol && 'cursor-pointer hover:bg-neutral-100 transition-colors select-none',
                    )}
                    onClick={!isCheckboxCol && col.sortable ? () => handleSort(String(col.accessor)) : undefined}
                  >
                    {isCheckboxCol ? (
                      <input
                        type="checkbox"
                        checked={allSelected}
                        ref={(el) => {
                          if (el && someSelected) {
                            el.indeterminate = true
                          }
                        }}
                        onChange={handleSelectAll}
                        className="rounded border-neutral-300 text-brand-600 focus:ring-brand-500 cursor-pointer"
                      />
                    ) : (
                      <>
                        {col.header}
                        {getSortIcon(col)}
                      </>
                    )}
                  </th>
                )
              })}
            </tr>
          </thead>
          <tbody className="divide-y divide-border bg-white">
            {loading
              ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    {displayColumns.map((_, colIdx) => (
                      <td key={colIdx} className="px-4 py-3">
                        <Skeleton className="h-4 w-full" />
                      </td>
                    ))}
                  </tr>
                ))
              : sortedData.map((row, idx) => {
                  const rowKeyVal = rowKey ? rowKey(row) : JSON.stringify(row)
                  const isSelected = selectedRows.has(rowKeyVal)

                  return (
                    <tr
                      key={rowKeyVal}
                      onClick={() => !selectable && onRowClick?.(row)}
                      className={cn(
                        'hover:bg-neutral-50 transition-colors',
                        !selectable && onRowClick && 'cursor-pointer',
                        selectable && isSelected && 'bg-neutral-50',
                      )}
                    >
                      {displayColumns.map((col) => {
                        const isCheckboxCol = col.accessor === '_checkbox'

                        return (
                          <td
                            key={String(col.accessor)}
                            className={cn('px-4 py-3', !isCheckboxCol && 'text-neutral-700', col.className)}
                            onClick={(e) => isCheckboxCol && e.stopPropagation()}
                          >
                            {isCheckboxCol ? (
                              <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => handleSelectRow(row)}
                                className="rounded border-neutral-300 text-brand-600 focus:ring-brand-500 cursor-pointer"
                              />
                            ) : col.cell ? (
                              col.cell(row)
                            ) : (
                              getCellValue(row, col.accessor as keyof T | string)
                            )}
                          </td>
                        )
                      })}
                    </tr>
                  )
                })}
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
            <span
              className={cn(
                'text-xs font-medium px-2',
                'bg-brand-600 text-white rounded',
              )}
            >
              {currentPage}
            </span>
            <span className="text-xs text-neutral-500">/ {totalPages}</span>
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
