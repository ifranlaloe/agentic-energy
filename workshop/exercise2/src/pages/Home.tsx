import { Link } from 'react-router-dom'
import { ArrowRight, FileText, Phone, Zap } from 'lucide-react'
import { Container } from '../components/ui/Container'
import { Card, CardBody } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { SkeletonCard } from '../components/ui/Skeleton'
import { useAsync } from '../lib/useAsync'
import { getOffers } from '../lib/api'
import type { PlanColour } from '../data/offers'

export function Home() {
  const { status, data: offers } = useAsync(getOffers)

  return (
    <div>
      {/* ── Hero ─────────────────────────────────────────────── */}
      <section className="bg-gradient-to-br from-brand-900 via-brand-800 to-brand-700 text-white py-16 sm:py-24">
        <Container>
          <div className="max-w-2xl">
            <p className="text-brand-300 text-sm font-medium uppercase tracking-widest mb-3">
              Northwind Energy
            </p>
            <h1 className="text-4xl sm:text-5xl font-bold tracking-tight leading-tight">
              Energy that works
              <br />
              for you
            </h1>
            <p className="mt-4 text-lg text-brand-200 max-w-lg">
              Simple, transparent energy plans for your home. No hidden fees, no surprises.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                to="/offers"
                className="inline-flex items-center gap-2 h-11 px-5 rounded-lg bg-white text-brand-800 font-medium text-sm hover:bg-brand-50 transition-colors"
              >
                Compare our plans
                <ArrowRight className="h-4 w-4" />
              </Link>
              <Link
                to="/contract"
                className="inline-flex items-center gap-2 h-11 px-5 rounded-lg border border-brand-500 text-white font-medium text-sm hover:bg-brand-800 transition-colors"
              >
                <FileText className="h-4 w-4" />
                View my contract
              </Link>
            </div>
          </div>
        </Container>
      </section>

      {/* ── Plan teasers ─────────────────────────────────────── */}
      <section className="py-12 sm:py-16">
        <Container>
          <div className="flex items-baseline justify-between gap-4 flex-wrap">
            <div>
              <h2 className="text-2xl font-bold text-slate-900">Our energy plans</h2>
              <p className="mt-1 text-slate-500">Three plans, each designed for a different need.</p>
            </div>
            <Link
              to="/offers"
              className="text-sm text-brand-600 hover:underline whitespace-nowrap"
            >
              Compare all plans →
            </Link>
          </div>

          <div className="mt-6 grid grid-cols-1 sm:grid-cols-3 gap-4">
            {status === 'loading' && (
              <>
                <SkeletonCard />
                <SkeletonCard />
                <SkeletonCard />
              </>
            )}

            {status === 'success' &&
              offers.map((offer) => (
                <Card key={offer.id} className="flex flex-col">
                  <CardBody className="flex flex-col flex-1">
                    <Badge variant={offer.colour as PlanColour}>
                      {offer.priceType === 'variable' ? 'Variable price' : 'Fixed price'}
                    </Badge>
                    <h3 className="mt-3 text-xl font-semibold text-slate-900">{offer.name}</h3>
                    <p className="mt-1 text-slate-500 text-sm">{offer.tagline}</p>
                    <ul className="mt-3 space-y-1 flex-1">
                      {offer.highlights.map((h) => (
                        <li key={h} className="flex items-start gap-2 text-sm text-slate-600">
                          <Zap className="h-3.5 w-3.5 text-brand-500 fill-brand-500 mt-0.5 shrink-0" />
                          {h}
                        </li>
                      ))}
                    </ul>
                    <p className="mt-4 text-slate-700 text-sm border-t border-slate-100 pt-3">
                      Est.{' '}
                      <span className="font-semibold text-slate-900 text-base">
                        €{offer.estimatedMonthly}
                      </span>{' '}
                      / month
                    </p>
                  </CardBody>
                </Card>
              ))}
          </div>
        </Container>
      </section>

      {/* ── Quick links ──────────────────────────────────────── */}
      <section className="border-t border-slate-100 py-8">
        <Container>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 max-w-2xl">
            <Link
              to="/contract"
              className="flex items-center gap-3 p-4 rounded-xl hover:bg-slate-50 transition-colors group"
            >
              <div className="h-10 w-10 rounded-full bg-brand-50 flex items-center justify-center shrink-0">
                <FileText className="h-5 w-5 text-brand-600" />
              </div>
              <div className="min-w-0">
                <p className="font-medium text-slate-900">My contract</p>
                <p className="text-sm text-slate-500">View your current plan</p>
              </div>
              <ArrowRight className="h-4 w-4 text-slate-400 ml-auto shrink-0 group-hover:translate-x-0.5 transition-transform" />
            </Link>

            <Link
              to="/contact"
              className="flex items-center gap-3 p-4 rounded-xl hover:bg-slate-50 transition-colors group"
            >
              <div className="h-10 w-10 rounded-full bg-brand-50 flex items-center justify-center shrink-0">
                <Phone className="h-5 w-5 text-brand-600" />
              </div>
              <div className="min-w-0">
                <p className="font-medium text-slate-900">Contact</p>
                <p className="text-sm text-slate-500">Questions? We're here.</p>
              </div>
              <ArrowRight className="h-4 w-4 text-slate-400 ml-auto shrink-0 group-hover:translate-x-0.5 transition-transform" />
            </Link>
          </div>
        </Container>
      </section>
    </div>
  )
}
