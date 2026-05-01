import axios from 'axios'

const TOKEN_KEY = 'vernonedu_token'

export const apiClient = axios.create({
  baseURL: '/api/v1',
  headers: { 'Content-Type': 'application/json' },
})

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY)
  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`
  }
  return config
})

// Response interceptor for 401 is set up in AuthContext to access persist/clear
// This export is used by AuthContext to register the interceptor
export default apiClient
