/**
 * Returns a helper to build paths scoped to the current company context.
 * Usage: const path = useCompanyPath(); navigate(path('users'))  →  /c/CORP-01/users
 *
 * Note: VernonEdu is single-tenant, so company paths always resolve to '/'.
 */
export function useCompanyPath() {
  return (segment: string) => `/${segment}`
}
