import { ReactNode } from 'react'
import PageHeader from '@/components/shared/PageHeader'
import SearchInput from '@/components/shared/SearchInput'
import FilterTabs from '@/components/shared/FilterTabs'
import TableCard from '@/components/shared/TableCard'
import DataTable, { Column } from '@/components/shared/DataTable'

interface SearchConfig {
  value: string
  onChange: (v: string) => void
  placeholder?: string
}

interface FilterTabsConfig {
  tabs: { label: string; value: string }[]
  active: string
  onChange: (v: string) => void
}

interface ListPageTemplateProps<T> {
  title: string
  subtitle?: string
  actions?: ReactNode

  search?: SearchConfig
  filterTabs?: FilterTabsConfig
  filters?: ReactNode

  columns: Column<T>[]
  data: T[]
  loading: boolean
  pagination: { page: number; limit: number; total: number }
  onPageChange: (page: number) => void
  rowKey: (row: T) => string
  onRowClick?: (row: T) => void
}

export default function ListPageTemplate<T>({
  title,
  subtitle,
  actions,
  search,
  filterTabs,
  filters,
  columns,
  data,
  loading,
  pagination,
  onPageChange,
  rowKey,
  onRowClick,
}: ListPageTemplateProps<T>) {
  const hasFilters = search || filterTabs || filters

  return (
    <div className="space-y-5">
      <PageHeader title={title} subtitle={subtitle} actions={actions} />

      {hasFilters && (
        <div className="flex flex-col sm:flex-row gap-3">
          {search && (
            <SearchInput
              value={search.value}
              onChange={search.onChange}
              placeholder={search.placeholder}
              className="flex-1"
            />
          )}
          {filterTabs && (
            <FilterTabs
              tabs={filterTabs.tabs}
              active={filterTabs.active}
              onChange={filterTabs.onChange}
            />
          )}
          {filters}
        </div>
      )}

      <TableCard>
        <DataTable
          columns={columns}
          data={data}
          loading={loading}
          pagination={pagination}
          onPageChange={onPageChange}
          rowKey={rowKey}
          onRowClick={onRowClick}
        />
      </TableCard>
    </div>
  )
}
