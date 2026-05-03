import * as RadixAvatar from '@radix-ui/react-avatar'
import { cn } from '@/lib/utils/cn'
import { forwardRef } from 'react'

interface AvatarProps extends React.HTMLAttributes<HTMLDivElement> {
  src?: string
  alt?: string
  fallback: string
  size?: 'sm' | 'md' | 'lg'
}

const sizeMap = { sm: 'h-7 w-7 text-xs', md: 'h-8 w-8 text-sm', lg: 'h-10 w-10 text-base' }

const Avatar = forwardRef<HTMLDivElement, AvatarProps>(
  ({ src, alt, fallback, size = 'md', className, ...props }, ref) => (
    <RadixAvatar.Root ref={ref} className={cn('relative inline-flex shrink-0 overflow-hidden rounded-full', sizeMap[size], className)} {...props}>
      {src && <RadixAvatar.Image src={src} alt={alt} className="aspect-square h-full w-full" />}
      <RadixAvatar.Fallback className="flex h-full w-full items-center justify-center rounded-full bg-brand-100 font-bold text-brand-700">
        {fallback}
      </RadixAvatar.Fallback>
    </RadixAvatar.Root>
  ),
)
Avatar.displayName = 'Avatar'
export default Avatar
