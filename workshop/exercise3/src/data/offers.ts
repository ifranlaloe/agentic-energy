export type PlanKey = 'flex' | 'zeker' | 'groen'
export type PlanColour = 'amber' | 'blue' | 'emerald'

export interface Offer {
  id: PlanKey
  name: string
  tagline: string
  priceType: 'variable' | 'fixed'
  contractPeriod: string
  estimatedMonthly: number
  highlights: string[]
  colour: PlanColour
  earlyExitFee: string
  renewableElectricity: boolean
}

export const offers: Offer[] = [
  {
    id: 'flex',
    name: 'Flex',
    tagline: 'Freedom to change',
    priceType: 'variable',
    contractPeriod: 'No fixed term',
    estimatedMonthly: 138,
    highlights: ['Variable energy price', 'No fixed contract period', 'Cancel at any time'],
    colour: 'amber',
    earlyExitFee: 'None',
    renewableElectricity: false,
  },
  {
    id: 'zeker',
    name: 'Zeker',
    tagline: 'Price certainty',
    priceType: 'fixed',
    contractPeriod: '1 year',
    estimatedMonthly: 129,
    highlights: [
      'Fixed energy price for 1 year',
      'Predictable monthly costs',
      'No surprises on your bill',
    ],
    colour: 'blue',
    earlyExitFee: '€75',
    renewableElectricity: false,
  },
  {
    id: 'groen',
    name: 'Groen',
    tagline: 'Renewable electricity',
    priceType: 'fixed',
    contractPeriod: '1 year',
    estimatedMonthly: 142,
    highlights: [
      'Fixed price for 1 year',
      '100% renewable electricity',
      'Verified green sourcing certificate',
    ],
    colour: 'emerald',
    earlyExitFee: '€75',
    renewableElectricity: true,
  },
]
