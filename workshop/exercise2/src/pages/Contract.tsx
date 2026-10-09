import { Container } from '../components/ui/Container'
import { PageHeader } from '../components/ui/PageHeader'
import { Card, CardHeader, CardBody } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { Skeleton } from '../components/ui/Skeleton'
import { useAsync } from '../lib/useAsync'
import { getContract, getRecentUsage } from '../lib/api'

export function Contract() {
  const contractState = useAsync(getContract)
  const usageState = useAsync(getRecentUsage)

  return (
    <div className="bg-slate-50 min-h-screen">
      <Container className="py-8">
        <PageHeader
          title="My contract"
          description="Your current energy plan and recent usage."
        />

        {/* ── Contract details ───────────────────────────────── */}
        {contractState.status === 'loading' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 bg-white rounded-xl border border-slate-200 p-6 space-y-4">
              <Skeleton className="h-5 w-1/4" />
              <Skeleton className="h-4 w-3/4" />
              <Skeleton className="h-4 w-2/3" />
              <Skeleton className="h-4 w-1/2" />
            </div>
            <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-3">
              <Skeleton className="h-5 w-1/2" />
              <Skeleton className="h-10 w-1/3" />
            </div>
          </div>
        )}

        {contractState.status === 'success' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <Card className="lg:col-span-2">
              <CardHeader>
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <h2 className="text-lg font-semibold text-slate-900">Plan details</h2>
                    <p className="text-sm text-slate-500 mt-0.5">
                      {contractState.data.accountNumber}
                    </p>
                  </div>
                  <Badge variant="brand">{contractState.data.plan}</Badge>
                </div>
              </CardHeader>
              <CardBody>
                <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-4 text-sm">
                  {[
                    { label: 'Account holder', value: contractState.data.customerName },
                    { label: 'Address',         value: contractState.data.address },
                    { label: 'Contract start',  value: contractState.data.startDate },
                    {
                      label: 'Contract end',
                      value: contractState.data.endDate ?? 'No fixed end date',
                    },
                    { label: 'Meter number',    value: contractState.data.meterNumber },
                  ].map(({ label, value }) => (
                    <div key={label}>
                      <dt className="text-slate-500">{label}</dt>
                      <dd className="mt-0.5 font-medium text-slate-900">{value}</dd>
                    </div>
                  ))}
                </dl>
              </CardBody>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-lg font-semibold text-slate-900">Monthly estimate</h2>
              </CardHeader>
              <CardBody>
                <p className="text-4xl font-bold text-slate-900">
                  €{contractState.data.estimatedMonthly}
                </p>
                <p className="text-sm text-slate-500 mt-1">per month (estimated)</p>
                <p className="text-xs text-slate-400 mt-3">
                  Based on average household usage. Actual costs depend on consumption.
                </p>
              </CardBody>
            </Card>
          </div>
        )}

        {/* ── Recent usage ───────────────────────────────────── */}
        {usageState.status === 'success' && (
          <Card className="mt-6">
            <CardHeader>
              <h2 className="text-lg font-semibold text-slate-900">Recent usage</h2>
              <p className="text-sm text-slate-500 mt-0.5">Last 6 months</p>
            </CardHeader>
            <CardBody>
              <div className="grid grid-cols-3 sm:grid-cols-6 gap-4">
                {usageState.data.map((month) => {
                  const maxCost = Math.max(...usageState.data.map((m) => m.cost))
                  const barHeight = Math.round((month.cost / maxCost) * 48)
                  return (
                    <div key={month.month} className="flex flex-col items-center gap-1">
                      <div className="h-12 flex items-end w-full">
                        <div
                          className="w-full bg-brand-200 rounded-sm"
                          style={{ height: `${barHeight}px` }}
                        />
                      </div>
                      <p className="text-xs font-medium text-slate-500">{month.month}</p>
                      <p className="text-sm font-semibold text-slate-900">€{month.cost}</p>
                      <p className="text-xs text-slate-400">{month.kwh} kWh</p>
                    </div>
                  )
                })}
              </div>
            </CardBody>
          </Card>
        )}
      </Container>
    </div>
  )
}
