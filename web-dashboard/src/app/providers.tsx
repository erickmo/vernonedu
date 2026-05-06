import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ToastProvider } from '@/widgets/Toast/Toast'
import { DeleteConfirmModalProvider } from '@/widgets/Modals/DeleteConfirmModal'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 0,
      retry: 1,
      refetchOnWindowFocus: true,
    },
  },
})

interface ProvidersProps {
  children: React.ReactNode
}

export function Providers({ children }: ProvidersProps) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ToastProvider />
      <DeleteConfirmModalProvider />
    </QueryClientProvider>
  )
}
