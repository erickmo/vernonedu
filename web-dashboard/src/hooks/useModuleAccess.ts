export interface ModuleAccess {
  readonly: boolean
  managedByHQ: boolean
}

/**
 * VernonEdu is single-tenant — all modules have full access.
 */
export function useModuleAccess(): ModuleAccess {
  return { readonly: false, managedByHQ: false }
}
