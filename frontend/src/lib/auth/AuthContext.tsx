import { createContext, useCallback, useEffect, useState, ReactNode } from 'react'
import { apiClient } from '@/lib/api/client'

export interface User {
  id: string
  email: string
  role: string
  name: string
}

export interface AuthContextType {
  user: User | null
  token: string | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  isAuthenticated: boolean
  isLoading: boolean
}

export const AuthContext = createContext<AuthContextType | null>(null)

const TOKEN_KEY = 'vernonedu_token'
const USER_KEY = 'vernonedu_user'

interface LoginResponse {
  access_token: string
  user: User
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem(TOKEN_KEY))
  const [user, setUser] = useState<User | null>(() => {
    const stored = localStorage.getItem(USER_KEY)
    return stored ? (JSON.parse(stored) as User) : null
  })
  const [isLoading, setIsLoading] = useState(true)

  const persist = useCallback((t: string, u: User) => {
    localStorage.setItem(TOKEN_KEY, t)
    localStorage.setItem(USER_KEY, JSON.stringify(u))
    setToken(t)
    setUser(u)
  }, [])

  const clear = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
    setToken(null)
    setUser(null)
  }, [])

  useEffect(() => {
    const interceptor = apiClient.interceptors.response.use(
      (res) => res,
      async (error) => {
        const originalRequest = error.config as typeof error.config & { _retry?: boolean }
        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true
          try {
            const res = await apiClient.post<{ access_token: string; user: User }>('/auth/refresh')
            persist(res.data.access_token, res.data.user)
            originalRequest.headers['Authorization'] = `Bearer ${res.data.access_token}`
            return apiClient(originalRequest)
          } catch {
            clear()
          }
        }
        return Promise.reject(error)
      }
    )
    return () => apiClient.interceptors.response.eject(interceptor)
  }, [persist, clear])

  useEffect(() => {
    if (!token) {
      setIsLoading(false)
      return
    }
    apiClient
      .get<{ data: User } | User>('/auth/me')
      .then((res) => {
        const u = (res.data as { data?: User }).data ?? (res.data as User)
        setUser(u)
        localStorage.setItem(USER_KEY, JSON.stringify(u))
      })
      .catch(() => clear())
      .finally(() => setIsLoading(false))
  }, [token, clear])

  const login = useCallback(
    async (email: string, password: string) => {
      const res = await apiClient.post<LoginResponse>('/auth/login', { email, password })
      persist(res.data.access_token, res.data.user)
    },
    [persist]
  )

  const logout = useCallback(() => {
    apiClient.post('/auth/logout').catch(() => null).finally(clear)
  }, [clear])

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        login,
        logout,
        isAuthenticated: !!token && !!user,
        isLoading,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}
