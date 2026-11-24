import { type HTMLAttributes } from 'react'
import { cn } from '../../lib/cn'

interface PageHeaderProps extends HTMLAttributes<HTMLDivElement> {
  title: string
  description?: string
}

export function PageHeader({ title, description, className, ...props }: PageHeaderProps) {
  return (
    <div className={cn('py-8 sm:py-12', className)} {...props}>
      <h1 className="text-3xl font-bold text-slate-900 tracking-tight">{title}</h1>
      {description && <p className="mt-2 text-lg text-slate-500">{description}</p>}
    </div>
  )
}
