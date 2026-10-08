/**
 * Fake in-process API client.
 *
 * Returns typed data with a short delay to simulate network behaviour.
 * There is no server – all data lives in src/data/.
 */
import type { Offer } from '../data/offers'
import type { Contract } from '../data/contract'
import type { UsageMonth } from '../data/usage'
import { offers as offersData } from '../data/offers'
import { contract as contractData } from '../data/contract'
import { recentUsage as usageData } from '../data/usage'

const delay = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms))

export async function getOffers(): Promise<Offer[]> {
  await delay(250)
  return offersData
}

export async function getContract(): Promise<Contract> {
  await delay(200)
  return contractData
}

export async function getRecentUsage(): Promise<UsageMonth[]> {
  await delay(200)
  return usageData
}
