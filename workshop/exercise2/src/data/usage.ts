export interface UsageMonth {
  month: string
  kwh: number
  cost: number
}

export const recentUsage: UsageMonth[] = [
  { month: 'May', kwh: 186, cost: 106 },
  { month: 'Jun', kwh: 174, cost:  99 },
  { month: 'Jul', kwh: 198, cost: 112 },
  { month: 'Aug', kwh: 185, cost: 105 },
  { month: 'Sep', kwh: 210, cost: 119 },
  { month: 'Oct', kwh: 241, cost: 137 },
]
