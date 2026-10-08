import { CheckCircle } from 'lucide-react'
import { cn } from '../../lib/cn'
import { Badge } from '../ui/Badge'
import type { Offer, PlanColour } from '../../data/offers'

interface OfferCardProps {
  offer: Offer
  selected?: boolean
  onSelect?: (id: string) => void
  className?: string
}

const colourRing: Record<PlanColour, string> = {
  amber:   'ring-amber-400',
  blue:    'ring-brand-500',
  emerald: 'ring-emerald-500',
}

const colourHeader: Record<PlanColour, string> = {
  amber:   'bg-amber-50 border-amber-200',
  blue:    'bg-brand-50 border-brand-200',
  emerald: 'bg-emerald-50 border-emerald-200',
}

export function OfferCard({ offer, selected = false, onSelect, className }: OfferCardProps) {
  return (
    <div
      className={cn(
        'relative bg-white rounded-xl border-2 transition-all flex flex-col',
        selected
          ? `border-transparent ring-2 ${colourRing[offer.colour]} shadow-md`
          : 'border-slate-200 shadow-sm hover:border-slate-300',
        className
      )}
    >
      {/* Header */}
      <div className={cn('px-6 py-5 rounded-t-xl border-b', colourHeader[offer.colour])}>
        <div className="flex items-start justify-between gap-2">
          <div>
            <h3 className="text-xl font-bold text-slate-900">{offer.name}</h3>
            <p className="text-sm text-slate-600 mt-0.5">{offer.tagline}</p>
          </div>
          <Badge variant={offer.colour}>
            {offer.priceType === 'variable' ? 'Variable' : 'Fixed'}
          </Badge>
        </div>
        <div className="mt-4">
          <span className="text-3xl font-bold text-slate-900">€{offer.estimatedMonthly}</span>
          <span className="text-slate-500 text-sm"> / month est.</span>
        </div>
      </div>

      {/* Features */}
      <div className="px-6 py-5 flex-1">
        <ul className="space-y-2.5">
          {offer.highlights.map((h) => (
            <li key={h} className="flex items-start gap-2.5 text-sm text-slate-700">
              <CheckCircle className="h-4 w-4 text-slate-400 mt-0.5 shrink-0" />
              {h}
            </li>
          ))}
        </ul>

        <dl className="mt-5 space-y-2 text-sm border-t border-slate-100 pt-4">
          <div className="flex justify-between gap-2">
            <dt className="text-slate-500">Contract period</dt>
            <dd className="font-medium text-slate-900 text-right">{offer.contractPeriod}</dd>
          </div>
          <div className="flex justify-between gap-2">
            <dt className="text-slate-500">Early exit fee</dt>
            <dd className="font-medium text-slate-900 text-right">{offer.earlyExitFee}</dd>
          </div>
          <div className="flex justify-between gap-2">
            <dt className="text-slate-500">Renewable electricity</dt>
            <dd className="font-medium text-slate-900 text-right">
              {offer.renewableElectricity ? '✓ Yes' : 'No'}
            </dd>
          </div>
        </dl>
      </div>

      {/* CTA */}
      <div className="px-6 pb-6">
        <button
          onClick={() => onSelect?.(offer.id)}
          className={cn(
            'w-full h-10 rounded-lg font-medium text-sm transition-colors',
            selected
              ? 'bg-slate-900 text-white hover:bg-slate-800'
              : 'bg-brand-700 text-white hover:bg-brand-800'
          )}
        >
          {selected ? 'Selected ✓' : 'Choose this plan'}
        </button>
      </div>
    </div>
  )
}
