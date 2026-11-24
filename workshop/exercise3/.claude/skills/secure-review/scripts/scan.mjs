import { readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'

const SOURCE_FILE = /\.(ts|tsx|html)$/
const root = process.argv[2] ?? 'src'

const rules = [
  { id: 'dangerous-inner-html', severity: 'High', cwe: 'CWE-79', pattern: /dangerouslySetInnerHTML/ },
  { id: 'inner-html-assignment', severity: 'High', cwe: 'CWE-79', pattern: /\.innerHTML\s*=/ },
  { id: 'eval-call', severity: 'High', cwe: 'CWE-95', pattern: /\beval\(/ },
  { id: 'function-constructor', severity: 'High', cwe: 'CWE-95', pattern: /new Function\(/ },
  {
    id: 'hardcoded-secret',
    severity: 'High',
    cwe: 'CWE-798',
    pattern: /(api[_-]?key|secret|token|passw(or)?d)\s*[:=]\s*['"][^'"]{8,}['"]/i,
  },
  { id: 'document-write', severity: 'Medium', cwe: 'CWE-79', pattern: /document\.write\(/ },
  { id: 'browser-storage', severity: 'Medium', cwe: 'CWE-922', pattern: /\b(local|session)Storage\b/ },
  {
    id: 'cleartext-url',
    severity: 'Medium',
    cwe: 'CWE-319',
    pattern: /http:\/\/(?!localhost|127\.0\.0\.1|www\.w3\.org)/,
  },
  {
    id: 'personal-data-in-log',
    severity: 'Medium',
    cwe: 'CWE-532',
    pattern: /console\.\w+\(.*(email|phone|address|password|firstName|lastName)/i,
  },
  {
    id: 'blank-target-without-noopener',
    severity: 'Low',
    cwe: 'CWE-1022',
    pattern: /target="_blank"(?!.*noopener)/,
  },
]

const sourceFiles = readdirSync(root, { recursive: true })
  .filter((file) => SOURCE_FILE.test(file))
  .map((file) => join(root, file))

const findLeads = (file) =>
  readFileSync(file, 'utf8')
    .split('\n')
    .flatMap((line, index) =>
      rules
        .filter((rule) => rule.pattern.test(line))
        .map((rule) => ({ ...rule, location: `${file}:${index + 1}` }))
    )

const leads = sourceFiles.flatMap(findLeads)

leads.forEach((lead) => console.log(`${lead.severity} ${lead.cwe} ${lead.location} ${lead.id}`))
console.log(`${leads.length} lead(s) to verify by reading the code. A lead is not a finding.`)
process.exit(leads.some((lead) => lead.severity === 'High') ? 1 : 0)
