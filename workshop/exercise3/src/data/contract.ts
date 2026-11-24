export interface Contract {
  customerName: string
  accountNumber: string
  address: string
  plan: string
  planKey: string
  startDate: string
  endDate: string | null
  estimatedMonthly: number
  meterNumber: string
}

export const contract: Contract = {
  customerName: 'A. van der Berg',
  accountNumber: 'NW-2025-04891',
  address: 'Hoofdstraat 42, 1234 AB Amsterdam',
  plan: 'Zeker',
  planKey: 'zeker',
  startDate: '1 January 2025',
  endDate: '31 December 2025',
  estimatedMonthly: 129,
  meterNumber: 'EAN 871234567890123456',
}
