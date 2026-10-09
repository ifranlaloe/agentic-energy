import { useState, useEffect } from 'react'

type AsyncState<T> =
  | { status: 'loading'; data: undefined; error: undefined }
  | { status: 'success'; data: T; error: undefined }
  | { status: 'error'; data: undefined; error: Error }

/**
 * Run an async function once on mount and track its state.
 * Pass a stable (non-inline) function to avoid repeated calls.
 */
export function useAsync<T>(fn: () => Promise<T>): AsyncState<T> {
  const [state, setState] = useState<AsyncState<T>>({
    status: 'loading',
    data: undefined,
    error: undefined,
  })

  useEffect(() => {
    let cancelled = false
    fn().then(
      (data) => {
        if (!cancelled) setState({ status: 'success', data, error: undefined })
      },
      (err) => {
        if (!cancelled)
          setState({
            status: 'error',
            data: undefined,
            error: err instanceof Error ? err : new Error(String(err)),
          })
      }
    )
    return () => {
      cancelled = true
    }
    // fn is intentionally omitted from deps – callers pass module-level functions
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return state
}
