import { useLocation } from 'react-router-dom'

export type DashboardContext = 'hq' | 'company'

/**
 * Hook untuk mendeteksi konteks dashboard saat ini (HQ atau Company).
 * - Jika URL dimulai dengan /g/, konteks adalah HQ
 * - Jika URL dimulai dengan /c/, konteks adalah Company
 *
 * Note: VernonEdu is single-tenant, so default fallback is 'hq'.
 */
export function useDashboardContext(): DashboardContext {
  const location = useLocation()

  // Jika path dimulai dengan /g/, ini adalah HQ context
  if (location.pathname.startsWith('/g/')) {
    return 'hq'
  }

  // Jika path dimulai dengan /c/, ini adalah Company context
  if (location.pathname.startsWith('/c/')) {
    return 'company'
  }

  // Default fallback: single-tenant, treat as HQ
  return 'hq'
}
