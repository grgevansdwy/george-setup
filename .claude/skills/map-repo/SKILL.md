---
name: map-repo
description: Build or refresh the repo's knowledge base so Claude never has to read the whole codebase. Surveys the repo, fans out one explorer per area, and writes a short CLAUDE.md in each area plus a docs/knowledge/START_HERE.md map. Use on a large or unfamiliar repo, after a big restructure, or with --refresh to update only the areas that changed.
disable-model-invocation: true
argument-hint: "[directory to limit to] [--refresh] [--yes]"
---

# /map-repo — a knowledge base Claude loads piece by piece

Input: $ARGUMENTS (empty = the whole repo). `--refresh` = only redo areas whose code changed since they were last mapped. `--yes` skips the go/no-go question.

## Why this shape
Claude Code loads the root `CLAUDE.md` in every session, and loads a subdirectory's `CLAUDE.md` only when it starts working with files in that directory. So:
- the root file stays small and points to the map,
- each area carries its own notes, loaded only when needed,
- `docs/knowledge/START_HERE.md` holds what no single folder can: the list of areas and the flows that cross them.

## 1. Survey (here, cheaply)
- Count tracked files per directory, two levels deep: `git ls-files | cut -d/ -f1-2 | sort | uniq -c | sort -rn`. Go a level deeper only inside directories that are still large.
- Read the manifests and workspace config (`package.json` workspaces, `pnpm-workspace.yaml`, `go.work`, `Cargo.toml` members, `pyproject.toml`) to find the real units.
- Skip vendored, generated and build output: `node_modules`, `dist`, `build`, `.venv`, `vendor`, migrations, generated clients, lockfiles, assets.
- Pick the **areas**. An area is a unit someone would work in on its own: an app, a package, a service, or a large module. Not every folder. Rough guide: 10+ source files, or a clear boundary such as its own manifest. A small repo may have 3 areas, a monorepo 30. Split an area with more than ~150 files into sub-areas.
- With `--refresh`: read the stamp on the last line of each existing area `CLAUDE.md` (see step 3) and keep only areas where `git diff --name-only <sha>..HEAD -- <area>` is not empty, plus areas that have no file yet. If nothing changed, say so and stop.

Show the plan as a table (area → files → new / refresh / has a hand-written CLAUDE.md) and the rough cost: one explorer per area. Unless `--yes` was passed, ask "Map these areas?".

## 2. Fan-out
Spawn one **explorer** subagent per area, about 6 at a time, each batch **in a single message** so they run in parallel. Each prompt must be self-contained:
- the area path, and the names of the other areas (so it can name dependencies)
- "Read the entry points, the public interface, the tests and the config of this area. Don't read every file."
- "Return the area note in exactly this format, at most 50 lines. Every claim must come from code you read. Write `unknown` rather than guessing. Leave out anything a reader would see in ten seconds of looking at the folder."

```
# <area path>
<1-2 sentences: what this area is for.>

## Key files
- `path` — <role>   (5-10 entries: entry points and the files people actually change)

## How it works
<3-6 lines: the main flow through this area, with `path:symbol` references.>

## Depends on / used by
- Depends on: <other areas, external services>
- Used by: <other areas>

## Commands
- Test: `<command for this area only>`
- <other area-specific commands, or delete this section>

## Conventions and gotchas
- <only what differs from the rest of the repo, or what would surprise a newcomer>
```

Also ask each explorer for one extra line, outside the note: `FLOWS: <cross-area flows this area takes part in, e.g. "checkout: web → api → billing">`.

## 3. Write the area files
For each returned note:
- **Spot-check it.** Open two of the files it names and confirm they exist and do what the note says. Drop any line you can't confirm.
- **No existing `CLAUDE.md` in the area:** write the note to `<area>/CLAUDE.md`.
- **Existing file written by this skill** (it ends with a stamp): replace it.
- **Existing hand-written file** (no stamp): don't replace it. Keep its content, add only the sections it lacks, and show the user the diff.
- End every file you write with the stamp, on the last line:
  `<!-- map-repo: <output of git rev-parse --short HEAD> <YYYY-MM-DD> -->`
- Never put secrets in these files, and keep each one under 60 lines.

## 4. Write the map
Write `docs/knowledge/START_HERE.md` (on `--refresh`, update only the rows and flows that changed):

```
# Start here: map of <repo>

<2-3 sentences: what the system does and how the areas fit together.>

## Areas
| Area | What it does | Notes |
|---|---|---|
| `apps/web` | <one line> | `apps/web/CLAUDE.md` |

## Flows that cross areas
### <flow name>
1. `area` — <what happens> (`path:symbol`)
2. ...

## Where do I change…
| To change | Look in |
|---|---|
| <common task> | `path` |

## Glossary
- **<project term>** — <meaning>

<!-- map-repo: <sha> <date> -->
```

Build "Flows that cross areas" from the explorers' `FLOWS:` lines. For each flow named by two or more areas, trace it once (send one explorer if it isn't clear from the notes) and write the steps. Keep the whole file under 150 lines.

Then make sure the root `CLAUDE.md` points to it. Add this line under the codebase map if it's missing, and nothing else:
`- Map of the repo: docs/knowledge/START_HERE.md. Read it before exploring an area you don't know. Each area has its own CLAUDE.md.`

## 5. Report
```
Mapped <n> areas (<new> new, <refreshed> refreshed, <kept> hand-written kept)
Files: <list of CLAUDE.md files written> + docs/knowledge/START_HERE.md
Unconfirmed lines dropped: <count>
Not mapped: <areas skipped and why>
```
Suggest committing with `/recap`. Don't commit yourself.

## Rules
- These files are a map, not documentation of everything. If a note repeats what the code says plainly, cut it.
- Wrong notes are worse than missing ones: Claude will trust them. When in doubt, leave it out.
- Don't edit source code. This skill only writes `CLAUDE.md` files and `docs/knowledge/START_HERE.md`.
