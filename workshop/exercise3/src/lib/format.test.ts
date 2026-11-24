import { describe, expect, it } from 'vitest'
import { formatEuro } from './format'

describe('formatEuro', () => {
  it.each([
    [0, '€0'],
    [89, '€89'],
    [1250, '€1,250'],
  ])('formats %d as %s', (amount, expected) => {
    expect(formatEuro(amount)).toBe(expected)
  })
})
