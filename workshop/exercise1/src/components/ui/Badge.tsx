import { type HTMLAttributes } from 'react'
import { cn } from '../../lib/cn'

type BadgeVariant = 'brand' | 'blue' | 'emerald' | 'amber' | 'slate' | 'green' | 'red'

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant
}

const variants: Record<BadgeVariant, string> = {
  brand:   'bg-brand-100 text-brand-800',
  blue:    'bg-blue-100 text-blue-800',
  emerald: 'bg-emerald-100 text-emerald-800',
  green:   'bg-green-100 text-green-800',
  amber:   'bg-amber-100 text-amber-800',
  slate:   'bg-slate-100 text-slate-700',
  red:     'bg-red-100 text-red-700',
}

export function Badge({ variant = 'slate', className, children, ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
        variants[variant],
        className
      )}
      {...props}
    >
      {children}
    </span>
  )
}
