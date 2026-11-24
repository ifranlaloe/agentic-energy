import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'

const REQUIRED_SUBSECTIONS = [
  'Story',
  'Acceptance criteria',
  'Non-functional requirements',
  'Out of scope',
  'Assumptions and decisions',
]
const VAGUE_WORDS =
  /\b(fast|quick|quickly|easy|easily|intuitive|user[- ]friendly|seamless|robust|appropriate|properly|nice|modern|good)\b/i
const STORY = /As an? .+, I want .+ so that .+/i

const slug = process.argv[2]

if (!slug) {
  console.error('usage: node validate-requirements.mjs <slug>')
  process.exit(2)
}

const path = join('docs', 'plans', `${slug}.md`)

if (!existsSync(path)) {
  console.error(`missing ${path}`)
  process.exit(2)
}

const sectionBody = (text, level, title) => {
  const heading = `${'#'.repeat(level)} ${title}`
  const nextHeading = `#{1,${level}} `
  const match = text.match(
    new RegExp(`^${heading}\\n([\\s\\S]*?)(?=^${nextHeading}|$(?![\\s\\S]))`, 'm')
  )
  return match ? match[1].trim() : undefined
}

const requirements = sectionBody(readFileSync(path, 'utf8'), 2, 'Requirements')

if (requirements === undefined) {
  console.error(`missing "## Requirements" section in ${path}`)
  process.exit(2)
}

const criteria = (sectionBody(requirements, 3, 'Acceptance criteria') ?? '')
  .split(/^#### (?=AC-\d+)/m)
  .slice(1)
  .map((block) => ({ id: block.match(/^AC-\d+/)[0], body: block }))

const checkSubsections = () =>
  REQUIRED_SUBSECTIONS.filter((title) => !sectionBody(requirements, 3, title)).map(
    (title) => `missing or empty subsection "${title}"`
  )

const checkStory = () =>
  STORY.test(requirements) ? [] : ['story must read "As a ..., I want ... so that ..."']

const checkCriteria = () =>
  criteria.length === 0
    ? ['no acceptance criteria. Add "#### AC-1 <title>" headings']
    : criteria.flatMap(({ id, body }) => [
        ...['Given', 'When', 'Then']
          .filter((word) => !new RegExp(`\\b${word}\\b`).test(body))
          .map((word) => `${id} is missing "${word}"`),
        ...(VAGUE_WORDS.test(body) ? [`${id} uses a vague word: ${body.match(VAGUE_WORDS)[0]}`] : []),
      ])

const problems = [...checkSubsections(), ...checkStory(), ...checkCriteria()]

problems.forEach((problem) => console.log(`FAIL ${problem}`))
console.log(problems.length === 0 ? `OK ${path}` : `${problems.length} problem(s) in ${path}`)
process.exit(problems.length === 0 ? 0 : 1)
