---
name: explain
description: Explain how a part of this codebase works (a feature, flow, module, or file) in a beginner-friendly template, using the explorer subagent to investigate. Use when the user asks "how does X work", "explain X", or "walk me through X".
argument-hint: "<feature, file, or question>"
---

# /explain — make the codebase easy to understand

Question: $ARGUMENTS

## 1. Investigate (delegate)
Run the **explorer** subagent with the question. Ask it to trace the real code path and cite `path:LINE` for every step. If the question is broad, split it into up to 3 explorer runs in parallel (e.g. frontend, backend, data).

## 2. Explain using this exact template
```
## TL;DR
<1–2 sentences a newcomer would understand. No jargon, or define it.>

## The big picture
<What problem this part solves, and where it sits in the system. A small ASCII diagram if it helps.>

## Step by step
1. **<step name>**: <what happens> (`path:LINE`)
2. ...

## Key pieces
| File / symbol | What it does |
|---|---|
| `path` | ... |

## Example
<A concrete walk-through with real-looking input → output.>

## Watch out for
- <gotchas, surprising behavior, known fragility>

## Want to go deeper?
- <2–3 follow-up questions the user might ask next>
```
Keep it short. Use analogies when they help. If anything is uncertain, say so instead of inventing an answer.
