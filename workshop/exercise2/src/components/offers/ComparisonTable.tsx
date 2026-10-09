import { Check, X } from 'lucide-react'
import type { Offer } from '../../data/offers'

interface ComparisonTableProps {
  offers: Offer[]
}

type Row =
  | { label: string; kind: 'text';    values: string[] }
  | { label: string; kind: 'bool';    values: boolean[] }
  | { label: string; kind: 'price';   values: number[] }

function buildRows(offers: Offer[]): Row[] {
  return [
    {
      label: 'Estimated monthly cost',
      kind: 'price',
      values: offers.map((o) => o.estimatedMonthly),
    },
    {
      label: 'Price type',
      kind: 'text',
      values: offers.map((o) => (o.priceType === 'fixed' ? 'Fixed' : 'Variable')),
    },
    {
      label: 'Contract period',
      kind: 'text',
      values: offers.map((o) => o.contractPeriod),
    },
    {
      label: 'Early exit fee',
      kind: 'text',
      values: offers.map((o) => o.earlyExitFee),
    },
    {
      label: 'Renewable electricity',
      kind: 'bool',
      values: offers.map((o) => o.renewableElectricity),
    },
  ]
}

export function ComparisonTable({ offers }: ComparisonTableProps) {
  const rows = buildRows(offers)

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm border-collapse">
        <thead>
          <tr className="border-b border-slate-200">
            <th className="text-left py-3 pr-4 text-slate-500 font-medium w-40 sm:w-52" />
            {offers.map((o) => (
              <th key={o.id} className="py-3 px-3 text-center font-semibold text-slate-900">
                {o.name}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr
              key={row.label}
              className={i % 2 === 0 ? 'bg-white' : 'bg-slate-50'}
            >
              <td className="py-3 pr-4 text-slate-500">{row.label}</td>
              {row.kind === 'price' &&
                row.values.map((v, j) => (
                  <td key={j} className="py-3 px-3 text-center font-semibold text-slate-900">
                    €{v}<span className="text-slate-400 font-normal">/mo</span>
                  </td>
                ))}
              {row.kind === 'text' &&
                row.values.map((v, j) => (
                  <td key={j} className="py-3 px-3 text-center text-slate-700">
                    {v}
                  </td>
                ))}
              {row.kind === 'bool' &&
                row.values.map((v, j) => (
                  <td key={j} className="py-3 px-3 text-center">
                    {v ? (
                      <Check className="h-4 w-4 text-emerald-600 mx-auto" />
                    ) : (
                      <X className="h-4 w-4 text-slate-300 mx-auto" />
                    )}
                  </td>
                ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
