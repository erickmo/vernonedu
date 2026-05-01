import * as Avatar from '@radix-ui/react-avatar'
import { cn } from '@/lib/utils/cn'

const SIZE: Record<'sm' | 'md', string> = {
  sm: 'w-8 h-8 text-xs',
  md: 'w-10 h-10 text-sm',
}

interface AvatarInitialProps {
  name: string
  size?: 'sm' | 'md'
}

export default function AvatarInitial({ name, size = 'sm' }: AvatarInitialProps) {
  return (
    <Avatar.Root
      className={cn(
        'rounded-full bg-brand-50 flex items-center justify-center font-bold text-brand-700 shrink-0',
        SIZE[size]
      )}
    >
      <Avatar.Fallback delayMs={0}>
        {name.charAt(0).toUpperCase()}
      </Avatar.Fallback>
    </Avatar.Root>
  )
}
