import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'

const TYPESCRIPT_FILE = /\.(ts|tsx)$/

const { tool_input: toolInput } = JSON.parse(readFileSync(0, 'utf8'))

if (!TYPESCRIPT_FILE.test(toolInput?.file_path ?? '')) process.exit(0)

const { status, stdout, stderr } = spawnSync('npm run --silent typecheck', {
  shell: true,
  encoding: 'utf8',
})

if (status === 0) process.exit(0)

console.error(`${stdout}${stderr}`.trim())
process.exit(2)
