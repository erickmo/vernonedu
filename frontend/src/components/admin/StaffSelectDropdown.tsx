/**
 * StaffSelectDropdown Component
 * Reusable dropdown for selecting staff members (for leader assignment)
 */

import { forwardRef } from 'react'
import { Staff } from '@/types/department'
import Select from '@/components/ui/Select'

interface StaffSelectDropdownProps
  extends React.SelectHTMLAttributes<HTMLSelectElement> {
  staff: Staff[]
  placeholder?: string
  error?: boolean
}

const StaffSelectDropdown = forwardRef<
  HTMLSelectElement,
  StaffSelectDropdownProps
>(({ staff, placeholder = 'Pilih staf', error, ...props }, ref) => {
  return (
    <Select
      ref={ref}
      error={error}
      {...props}
    >
      <option value="">{placeholder}</option>
      {staff.map((member) => (
        <option key={member.id} value={member.id}>
          {member.name}
        </option>
      ))}
    </Select>
  )
})

StaffSelectDropdown.displayName = 'StaffSelectDropdown'

export default StaffSelectDropdown
