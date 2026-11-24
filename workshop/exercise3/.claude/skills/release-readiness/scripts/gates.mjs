import { readFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'

const TAIL_LINES = 12
const slug = process.argv[2]
const hasTestScript = Boolean(JSON.parse(readFileSync('package.json', 'utf8')).scripts?.test)

const gates = [
  { name: 'typecheck', command: 'npm run --silent typecheck' },
  { name: 'build', command: 'npm run --silent build' },
  hasTestScript
    ? { name: 'tests', command: 'npm test --silent' }
    : { name: 'tests', missing: 'no "test" script in package.json' },
  { name: 'maintainability', command: 'node .claude/skills/build-feature/scripts/check-maintainability.mjs' },
  { name: 'security scan', command: 'node .claude/skills/secure-review/scripts/scan.mjs' },
  slug
    ? { name: 'traceability', command: `node .claude/skills/verify-tests/scripts/trace.mjs ${slug}` }
    : { name: 'traceability', missing: 'no slug given' },
]

const run = ({ name, command, missing }) => {
  if (missing) return { name, result: 'NOT CONFIGURED', detail: missing }
  const { status, stdout, stderr } = spawnSync(command, { shell: true, encoding: 'utf8' })
  const detail = `${stdout}${stderr}`.trim().split('\n').slice(-TAIL_LINES).join('\n')
  return { name, result: status === 0 ? 'PASS' : 'FAIL', detail }
}

const outcomes = gates.map(run)

outcomes.forEach(({ name, result }) => console.log(`${result.padEnd(15)} ${name}`))
outcomes
  .filter(({ result }) => result !== 'PASS')
  .forEach(({ name, detail }) => console.log(`\n--- ${name}\n${detail}`))

process.exit(outcomes.every(({ result }) => result === 'PASS') ? 0 : 1)
