import { useState } from 'react'
import { CheckCircle, ArrowLeft } from 'lucide-react'
import { Link } from 'react-router-dom'
import { Container } from '../components/ui/Container'
import { PageHeader } from '../components/ui/PageHeader'
import { Card, CardHeader, CardBody } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { SkeletonCard } from '../components/ui/Skeleton'
import { OfferCard } from '../components/offers/OfferCard'
import { ComparisonTable } from '../components/offers/ComparisonTable'
import { useAsync } from '../lib/useAsync'
import { getOffers } from '../lib/api'
import type { PlanKey } from '../data/offers'

export function Offers() {
  const { status, data: offers } = useAsync(getOffers)
  const [selected, setSelected] = useState<PlanKey | null>(null)
  const [confirmed, setConfirmed] = useState(false)

  if (confirmed && offers) {
    const plan = offers.find((o) => o.id === selected)!
    return (
      <div className="bg-slate-50 min-h-screen">
        <Container className="py-16 text-center max-w-xl mx-auto">
          <CheckCircle className="h-16 w-16 text-emerald-500 mx-auto" />
          <h1 className="mt-4 text-2xl font-bold text-slate-900">You've chosen {plan.name}</h1>
          <p className="mt-2 text-slate-500">
            Great choice. We'll process your switch and send a confirmation by email.
          </p>
          <div className="mt-6 p-4 bg-white rounded-xl border border-slate-200 text-left">
            <p className="text-sm text-slate-500">Selected plan</p>
            <p className="font-semibold text-slate-900 text-lg">{plan.name} — {plan.tagline}</p>
            <p className="text-sm text-slate-600 mt-1">
              Est. €{plan.estimatedMonthly}/month · {plan.contractPeriod}
            </p>
          </div>
          <button
            className="mt-6 text-sm text-brand-600 hover:underline"
            onClick={() => { setConfirmed(false); setSelected(null) }}
          >
            ← Back to plans
          </button>
        </Container>
      </div>
    )
  }

  return (
    <div className="bg-slate-50 min-h-screen">
      <Container className="py-8">
        <Link
          to="/"
          className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-900 mb-6 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to home
        </Link>

        <PageHeader
          title="Energy plans"
          description="Compare our three plans and choose the one that fits your situation."
        />

        {/* ── Offer cards ─────────────────────────────────────── */}
        {status === 'loading' && (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
            <SkeletonCard className="h-80" />
            <SkeletonCard className="h-80" />
            <SkeletonCard className="h-80" />
          </div>
        )}

        {status === 'success' && (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
              {offers.map((offer) => (
                <OfferCard
                  key={offer.id}
                  offer={offer}
                  selected={selected === offer.id}
                  onSelect={(id) => setSelected(id as PlanKey)}
                />
              ))}
            </div>

            {/* ── Confirm selection ─────────────────────────── */}
            {selected && (
              <div className="mt-6 flex flex-col sm:flex-row items-center gap-4 p-5 bg-white rounded-xl border border-slate-200 shadow-sm">
                <div className="flex-1">
                  <p className="font-semibold text-slate-900">
                    You've selected{' '}
                    <span className="text-brand-700">
                      {offers.find((o) => o.id === selected)?.name}
                    </span>
                  </p>
                  <p className="text-sm text-slate-500 mt-0.5">
                    Ready to confirm? We'll switch you to this plan.
                  </p>
                </div>
                <div className="flex gap-3 shrink-0">
                  <Button variant="outline" size="sm" onClick={() => setSelected(null)}>
                    Cancel
                  </Button>
                  <Button size="sm" onClick={() => setConfirmed(true)}>
                    Confirm selection
                  </Button>
                </div>
              </div>
            )}

            {/* ── Full comparison table ─────────────────────── */}
            <Card className="mt-8">
              <CardHeader>
                <h2 className="text-lg font-semibold text-slate-900">Side-by-side comparison</h2>
              </CardHeader>
              <CardBody>
                <ComparisonTable offers={offers} />
              </CardBody>
            </Card>

            {/* ── Pricing note ─────────────────────────────── */}
            <p className="mt-4 text-xs text-slate-400 text-center">
              Estimated monthly costs are based on average household consumption of 3,000 kWh/year
              and are illustrative only. Actual costs depend on your usage.
            </p>
          </>
        )}
      </Container>
    </div>
  )
}
