import { Zap } from 'lucide-react'

export function SiteFooter() {
  return (
    <footer className="bg-slate-900 text-slate-400 mt-auto">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-8 flex flex-col sm:flex-row items-center justify-between gap-3">
        <div className="flex items-center gap-2 text-slate-300 font-medium text-sm">
          <Zap className="h-4 w-4 text-brand-400 fill-brand-400" />
          Northwind Energy
        </div>
        <p className="text-xs text-center">
          © 2025 Northwind Energy B.V. · Fictional company for workshop use only
        </p>
      </div>
    </footer>
  )
}
