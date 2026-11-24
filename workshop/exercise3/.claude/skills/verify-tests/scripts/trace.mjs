import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'

const TEST_FILE = /\.(test|spec)\.[jt]sx?$/
const slug = process.argv[2]

if (!slug) {
  console.error('usage: node trace.mjs <slug>')
  process.exit(2)
}

const planPath = join('docs', 'plans', `${slug}.md`)

if (!existsSync(planPath)) {
  console.error(`missing ${planPath}`)
  process.exit(2)
}

const requirements =
  readFileSync(planPath, 'utf8').match(/^## Requirements\n[\s\S]*?(?=^#{1,2} |$(?![\s\S]))/m)?.[0] ?? ''

const criteriaIds = [...requirements.matchAll(/^#### (AC-\d+)/gm)].map((match) => match[1])

const testFiles = ['src', 'tests']
  .filter(existsSync)
  .flatMap((dir) => readdirSync(dir, { recursive: true }).map((file) => join(dir, file)))
  .filter((file) => TEST_FILE.test(file))

const testSources = testFiles.map((file) => ({ file, source: readFileSync(file, 'utf8') }))

const rows = criteriaIds.map((id) => ({
  id,
  files: testSources.filter(({ source }) => source.includes(`[${id}]`)).map(({ file }) => file),
}))

rows.forEach(({ id, files }) => console.log(`${id} | ${files.length ? files.join(', ') : 'UNTRACED'}`))

const untraced = rows.filter(({ files }) => files.length === 0)
console.log(`${rows.length - untraced.length}/${rows.length} criteria traced to a test`)
process.exit(rows.length > 0 && untraced.length === 0 ? 0 : 1)
