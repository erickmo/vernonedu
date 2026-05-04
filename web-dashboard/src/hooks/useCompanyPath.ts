/**
 * Returns a helper to build simple paths (single-tenant — no company prefix).
 * Usage: const path = useCompanyPath(); navigate(path('users'))  →  /users
 */
export function useCompanyPath() {
  return (segment: string) => `/${segment}`
}
