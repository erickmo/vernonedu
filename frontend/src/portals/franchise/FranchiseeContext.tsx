import { createContext, useContext } from 'react'
import { useMyFranchisee, type Franchisee } from '@/lib/api/franchise'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface FranchiseeContextValue {
  franchisee: Franchisee
}

const FranchiseeContext = createContext<FranchiseeContextValue | null>(null)

export function useFranchiseeCtx(): FranchiseeContextValue {
  const ctx = useContext(FranchiseeContext)
  if (!ctx) throw new Error('useFranchiseeCtx must be used inside FranchiseeProvider')
  return ctx
}

export function FranchiseeProvider({ children }: { children: React.ReactNode }) {
  const { data: franchisee, isLoading, isError } = useMyFranchisee()

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (isError || !franchisee) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <p className="text-lg font-semibold text-neutral-800">No franchise account linked</p>
          <p className="text-sm text-neutral-500 mt-1">Contact your administrator to link your account.</p>
        </div>
      </div>
    )
  }

  return (
    <FranchiseeContext.Provider value={{ franchisee }}>
      {children}
    </FranchiseeContext.Provider>
  )
}
