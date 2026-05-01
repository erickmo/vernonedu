import { describe, it, expect } from 'vitest'
import { canAccess } from '../permissions'
import { ROLES } from '../roles'

describe('canAccess', () => {
  it('director can do anything on any resource', () => {
    expect(canAccess(ROLES.DIRECTOR, 'create', 'mastercourse')).toBe(true)
    expect(canAccess(ROLES.DIRECTOR, 'delete', 'enrollment')).toBe(true)
  })

  it('dept_leader can manage curriculum but not accounting', () => {
    expect(canAccess(ROLES.DEPT_LEADER, 'create', 'mastercourse')).toBe(true)
    expect(canAccess(ROLES.DEPT_LEADER, 'create', 'transaction')).toBe(false)
  })

  it('facilitator can only mark attendance', () => {
    expect(canAccess(ROLES.FACILITATOR, 'update', 'attendance')).toBe(true)
    expect(canAccess(ROLES.FACILITATOR, 'create', 'mastercourse')).toBe(false)
  })

  it('student can read own enrollment', () => {
    expect(canAccess(ROLES.STUDENT, 'read', 'enrollment.own')).toBe(true)
    expect(canAccess(ROLES.STUDENT, 'create', 'enrollment')).toBe(false)
  })

  it('unknown role returns false', () => {
    expect(canAccess('ghost' as any, 'read', 'mastercourse')).toBe(false)
  })

  it('unknown resource returns false', () => {
    expect(canAccess(ROLES.DIRECTOR, 'read', 'unicorn' as any)).toBe(false)
  })
})
