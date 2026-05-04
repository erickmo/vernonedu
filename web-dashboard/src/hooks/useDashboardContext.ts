export type DashboardContext = 'default'

/**
 * VernonEdu is single-tenant — always returns 'default'.
 */
export function useDashboardContext(): DashboardContext {
  return 'default'
}
