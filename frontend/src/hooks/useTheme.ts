import React from 'react'

export function useTheme() {
  return { theme: 'light' as const, setTheme: (_t: string) => {}, resolved: 'light' as const }
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return React.createElement(React.Fragment, null, children)
}

export function initTheme() {
  document.documentElement.classList.remove('dark')
}
