import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { VernonEduUser } from '@/types/auth.types'

interface AuthState {
  user: VernonEduUser | null
  token: string | null
  refreshToken: string | null
  isAuthenticated: boolean
}

interface AuthActions {
  login: (response: { access_token: string; refresh_token: string; user: VernonEduUser }) => void
  logout: () => void
  updateToken: (token: string, refreshToken: string) => void
}

const initialState: AuthState = {
  user: null,
  token: null,
  refreshToken: null,
  isAuthenticated: false,
}

export const useAuthStore = create<AuthState & AuthActions>()(
  persist(
    (set) => ({
      ...initialState,

      login: (response) => {
        set({
          user: response.user,
          token: response.access_token,
          refreshToken: response.refresh_token,
          isAuthenticated: true,
        })
      },

      logout: () => set(initialState),

      updateToken: (token: string, refreshToken: string) => {
        set({ token, refreshToken })
      },
    }),
    {
      name: 'dashboard-auth',
      partialize: (state) => ({
        token: state.token,
        refreshToken: state.refreshToken,
        isAuthenticated: state.isAuthenticated,
        user: state.user,
      }),
    },
  ),
)
