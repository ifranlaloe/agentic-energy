import { readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'

const MAX_FILE_LINES = 150
const SOURCE_FILE = /\.(ts|tsx)$/
const root = process.argv[2] ?? 'src'

const lineRules = [
  { id: 'explicit-any', pattern: /(:\s*any\b|\bas any\b|<any>)/ },
  { id: 'console-call', pattern: /\bconsole\.(log|debug)\(/ },
  { id: 'todo-marker', pattern: /\b(TODO|FIXME|HACK)\b/ },
  { id: 'raw-hex-colour', pattern: /#[0-9a-fA-F]{3,8}\b/ },
]

const sourceFiles = readdirSync(root, { recursive: true })
  .filter((file) => SOURCE_FILE.test(file))
  .map((file) => join(root, file))

const findLineFindings = (file, lines) =>
  lines.flatMap((line, index) =>
    lineRules
      .filter((rule) => rule.pattern.test(line))
      .map((rule) => `${file}:${index + 1} ${rule.id}`)
  )

const findFileFindings = (file, lines) =>
  lines.length > MAX_FILE_LINES ? [`${file}:1 file-too-long (${lines.length} lines)`] : []

const findings = sourceFiles.flatMap((file) => {
  const lines = readFileSync(file, 'utf8').split('\n')
  return [...findFileFindings(file, lines), ...findLineFindings(file, lines)]
})

findings.forEach((finding) => console.log(finding))
console.log(`${findings.length} maintainability finding(s)`)
process.exit(findings.length > 0 ? 1 : 0)
