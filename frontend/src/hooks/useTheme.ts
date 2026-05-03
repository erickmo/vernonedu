import React from 'react'
import { useSyncExternalStore, useCallback } from 'react'

type Theme = 'light' | 'dark' | 'system'

function getTheme(): Theme {
  return (localStorage.getItem('vernonedu_theme') as Theme) || 'system'
}

function applyTheme(theme: Theme) {
  const root = document.documentElement
  const resolved =
    theme === 'system'
      ? window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light'
      : theme
  root.classList.toggle('dark', resolved === 'dark')
}

const listeners = new Set<() => void>()
function subscribe(cb: () => void) {
  listeners.add(cb)
  return () => { listeners.delete(cb) }
}

export function useTheme() {
  const theme = useSyncExternalStore(subscribe, getTheme)

  const setTheme = useCallback((t: Theme) => {
    localStorage.setItem('vernonedu_theme', t)
    applyTheme(t)
    listeners.forEach((cb) => cb())
  }, [])

  const resolved =
    theme === 'system'
      ? window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light'
      : theme

  return { theme, setTheme, resolved } as const
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return <>{children}</>
}

export function initTheme() {
  applyTheme(getTheme())
  window
    .matchMedia('(prefers-color-scheme: dark)')
    .addEventListener('change', () => applyTheme(getTheme()))
}