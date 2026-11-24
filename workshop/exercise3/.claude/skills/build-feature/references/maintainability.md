# Maintainability patterns

Each pair shows the problem first, then the fix.

## Separate fetching from rendering

Problem: the component fetches, formats and renders.

```tsx
export function Plans() {
  const [offers, setOffers] = useState<Offer[]>([])
  useEffect(() => {
    getOffers().then(setOffers)
  }, [])
  return <ul>{offers.map((o) => <li key={o.id}>€{o.price}</li>)}</ul>
}
```

Fix: use `useAsync`, handle every state and format through the shared helper.

```tsx
export function Plans() {
  const offers = useAsync(getOffers)
  if (offers.status === 'loading') return <Skeleton />
  if (offers.status === 'error') return <p role="alert">Plans could not be loaded</p>
  return <ul>{offers.data.map((offer) => <li key={offer.id}>{formatEuro(offer.price)}</li>)}</ul>
}
```

## Guard clauses over nesting

Problem:

```ts
function submit(input: Input) {
  if (input.valid) {
    if (!pending) {
      send(input)
    }
  }
}
```

Fix:

```ts
function submit(input: Input) {
  if (!input.valid) return
  if (pending) return
  send(input)
}
```

## Name the numbers and strings

Problem: `if (message.length > 1000)`.

Fix: `const MAX_MESSAGE_LENGTH = 1000` next to the validator, used by both the validator and the input's `maxLength`.

## Type the boundary

Problem: `function handle(result: any)`.

Fix: a discriminated union such as `ValidationResult<T>`, so the compiler forces both branches to be handled.

## Extract on the second use

When the same markup or logic appears a second time, move it to `src/components/ui/` or `src/lib/` and use it in both places in the same change.
