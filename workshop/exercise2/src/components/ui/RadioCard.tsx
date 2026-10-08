import { type InputHTMLAttributes } from 'react'
import { cn } from '../../lib/cn'

interface RadioCardProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'onChange' | 'type'> {
  label: string
  description?: string
  onChange?: (value: string) => void
}

export function RadioCard({
  label,
  description,
  value,
  checked,
  onChange,
  className,
  ...props
}: RadioCardProps) {
  return (
    <label
      className={cn(
        'relative block cursor-pointer rounded-xl border-2 p-4 transition-all select-none',
        checked
          ? 'border-brand-600 bg-brand-50 shadow-sm'
          : 'border-slate-200 bg-white hover:border-slate-300',
        className
      )}
    >
      <input
        type="radio"
        value={value}
        checked={checked}
        onChange={() => onChange?.(value as string)}
        className="sr-only"
        {...props}
      />
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className={cn('font-medium text-sm', checked ? 'text-brand-900' : 'text-slate-900')}>
            {label}
          </p>
          {description && (
            <p className="mt-0.5 text-xs text-slate-500 leading-snug">{description}</p>
          )}
        </div>
        <div
          className={cn(
            'mt-0.5 h-4 w-4 rounded-full border-2 flex-shrink-0 transition-all',
            checked ? 'border-brand-600 bg-brand-600' : 'border-slate-300 bg-white'
          )}
        >
          {checked && (
            <div className="h-full w-full rounded-full bg-white scale-[0.4] block" />
          )}
        </div>
      </div>
    </label>
  )
}
