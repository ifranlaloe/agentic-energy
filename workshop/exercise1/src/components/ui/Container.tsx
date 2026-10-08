import { type HTMLAttributes } from 'react'
import { cn } from '../../lib/cn'

interface ContainerProps extends HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode
}

export function Container({ children, className, ...props }: ContainerProps) {
  return (
    <div className={cn('max-w-6xl mx-auto px-4 sm:px-6', className)} {...props}>
      {children}
    </div>
  )
}
