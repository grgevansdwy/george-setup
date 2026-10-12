---
name: investigate
description: Debug with competing hypotheses in parallel. Reproduces a failure, generates several distinct root-cause hypotheses, fans out one debugger subagent per hypothesis to prove or disprove it, then fans in by comparing evidence. Use when a bug's cause is unclear or a first debugging attempt anchored on the wrong theory.
disable-model-invocation: true
argument-hint: "<symptom, failing test, or error>"
---

# /investigate — parallel hypotheses for a bug

Symptom: $ARGUMENTS

## 1. Pin down the symptom (here, briefly)
- Find the smallest command that shows the failure (one test, one request, one script) and run it once. Record the exact error.
- If you can't reproduce it, stop and say what you tried. Parallel guessing without a reproduction wastes tokens.
- Gather cheap context: the stack trace, `git log --oneline -15`, and the diff of recently changed files near the failure. For a large unfamiliar area, send one **explorer** first.

## 2. Hypotheses
Write 3-4 hypotheses that are **genuinely different** (different layers or mechanisms, not variations of one idea). For example: bad input data / logic bug in X / environment or config / race or ordering / recent change Y. For each one, name the experiment that would settle it.

## 3. Fan-out
Spawn one **debugger** subagent per hypothesis, **in a single message**. Give each:
- the reproduction command and exact error
- its ONE assigned hypothesis and the suggested experiment
- "Prove or disprove this hypothesis. Don't fix. Don't disturb shared state."

If the experiments would fight over shared state (one database, fixed ports, global caches), tell the debuggers they are NOT isolated and must stay read-only, or run them two at a time instead.

## 4. Fan-in
- Put the verdicts side by side: hypothesis → CONFIRMED / RULED OUT / INCONCLUSIVE → strongest evidence.
- If exactly one is confirmed and the others are ruled out, that's the root cause.
- If several look plausible, check whether they're one cause seen from different sides. If they're truly separate, list them all.
- If nothing is confirmed, run **one** more round with new hypotheses based on what was ruled out. After two rounds, stop and report what is known.

## 5. Report
```
## Root cause: <one line>   (confidence: high/medium/low)
Reproduction: <command> → <error>

| Hypothesis | Verdict | Evidence |
|---|---|---|

Fix (not applied): <files and lines to change>
Regression test: <the test that would have caught it>
```
Ask whether to apply the fix. If yes, apply it, add the regression test (or hand it to **test-writer**), and rerun the reproduction.
