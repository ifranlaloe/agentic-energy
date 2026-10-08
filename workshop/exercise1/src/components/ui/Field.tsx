import { type HTMLAttributes } from 'react'
import { cn } from '../../lib/cn'

interface FieldProps extends HTMLAttributes<HTMLDivElement> {
  label: string
  htmlFor?: string
  error?: string
  hint?: string
}

export function Field({ label, htmlFor, error, hint, children, className, ...props }: FieldProps) {
  return (
    <div className={cn('flex flex-col gap-1.5', className)} {...props}>
      <label htmlFor={htmlFor} className="text-sm font-medium text-slate-700">
        {label}
      </label>
      {children}
      {hint && !error && <p className="text-xs text-slate-500">{hint}</p>}
      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  )
}

/** Shared input className – apply to any <input> inside a Field */
export const inputClass =
  'w-full h-10 rounded-lg border border-slate-300 px-3 text-sm bg-white ' +
  'focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent ' +
  'disabled:opacity-50 disabled:bg-slate-50'

export const textareaClass =
  'w-full rounded-lg border border-slate-300 px-3 py-2 text-sm bg-white ' +
  'focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent ' +
  'resize-none disabled:opacity-50 disabled:bg-slate-50'

export const selectClass = inputClass + ' cursor-pointer'
