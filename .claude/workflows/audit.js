export const meta = {
  name: 'audit',
  description: 'Fan-out audit: one agent per file checks for a concern, then independent agents try to refute each finding. Args: { dir, concern }',
  phases: ['Discover', 'Audit', 'Verify'],
}

// Usage: /audit audit src/routes for missing authorization checks
//   (Claude passes args; a string or { dir, concern } both work.)
const input = typeof args === 'string' ? { concern: args } : (args || {})
const dir = input.dir || 'src/'
const concern = input.concern || 'bugs that would cause wrong results or crashes in production'

phase('Discover')
const found = await agent(
  `List the source files under ${dir} that could plausibly contain: ${concern}. ` +
  `Skip tests, generated code, vendored code and build output. At most 60 files, most relevant first.`,
  {
    label: 'discover',
    schema: {
      type: 'object',
      required: ['files'],
      properties: { files: { type: 'array', items: { type: 'string' } } },
    },
  },
)
const files = (found && found.files) || []
log(`Auditing ${files.length} files for: ${concern}`)

phase('Audit')
const audits = await pipeline(files, file =>
  agent(
    `Audit ${file} for: ${concern}. Read the surrounding code (callers, guards, config) before ` +
    `deciding. Report only issues you can point to at a specific line. If there are none, return an empty list.`,
    {
      label: file,
      schema: {
        type: 'object',
        required: ['findings'],
        properties: {
          findings: {
            type: 'array',
            items: {
              type: 'object',
              required: ['location', 'problem', 'severity'],
              properties: {
                location: { type: 'string' },
                problem: { type: 'string' },
                severity: { type: 'string', enum: ['high', 'medium', 'low'] },
              },
            },
          },
        },
      },
    },
  ),
)
const findings = audits.filter(Boolean).flatMap(a => a.findings || [])
log(`${findings.length} raw findings; verifying`)

phase('Verify')
const verdicts = await pipeline(findings, f =>
  agent(
    `Another agent claims: "${f.problem}" at ${f.location} (severity ${f.severity}). ` +
    `Try to REFUTE it: read the code and its callers and look for the guard, validation or test ` +
    `that already handles it. Answer confirmed only if you found the concrete failing path.`,
    {
      label: `verify ${f.location}`,
      schema: {
        type: 'object',
        required: ['verdict', 'evidence'],
        properties: {
          verdict: { type: 'string', enum: ['confirmed', 'refuted', 'unverified'] },
          evidence: { type: 'string' },
        },
      },
    },
  ),
)

const results = findings.map((f, i) => ({ ...f, ...(verdicts[i] || { verdict: 'unverified', evidence: 'verifier did not finish' }) }))
return {
  concern,
  filesAudited: files.length,
  confirmed: results.filter(r => r.verdict === 'confirmed'),
  unverified: results.filter(r => r.verdict === 'unverified'),
  refutedCount: results.filter(r => r.verdict === 'refuted').length,
}
