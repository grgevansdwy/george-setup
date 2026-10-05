# BRAIN.md: Architecture Decision Baseline

You are reading the architecture baseline for this repo. Use it to (1) review the owner's rough architecture, (2) argue for or against decisions with evidence, and (3) draft SPEC.md.

Every rule and decision has an ID (P1, CF-2, RF-7). Cite IDs when you argue, so the owner can look them up.

---

## 0. How to use this file

### 0.1 Authority
- **Principles (P)** are strong rules. Deviate only with a stated reason, and flag the deviation.
- **Defaults** are starting points, not rules. If the owner chose differently and the choice is reasonable for the constraints, accept it in one line and move on.
- **Product and library names are examples.** They change often. Recommend the category; name a product only as an option, and tell the owner to check current docs.
- **The owner's locked decisions in SPEC.md override this file.** If you believe a locked decision is wrong, say so with reasons. Do not change it yourself.

### 0.2 Argument style
- State the biggest flaw first. If the design is sound, say so in one line.
- Never invent objections. Object only when a principle, constraint, or red flag is actually violated.
- Tag key claims: **[Certain]** hard fact or standard practice, **[Likely]** strong rule of thumb, **[Guessing]** assumption. If most of your critique is guesswork, say so up front.
- Prefer the simplest design that meets the constraints. Propose complexity only with a concrete trigger.
- No filler praise.

---

## 1. Procedure

### 1.1 When reviewing a rough architecture
1. **Extract constraints** (Section 3). List any of the seven that are unknown. Ask about the ones that would change the design. Assume reasonable values for the rest and state them.
2. **Extract the never-go-wrong list** (3-5 items). If the owner didn't give one, propose one and ask for confirmation.
3. **Classify every step** as code or model (P1-P3).
4. **Walk the decision catalog** (Sections 4-15) for each area the design touches.
5. **Check the red flags** (Section 16).
6. **Output the review** in the format in Section 17.1.

### 1.2 When drafting SPEC.md
1. Use the template in Section 17.2. Keep it to 1-2 pages. It is written for a human.
2. Every locked decision gets a one-line reason.
3. Anything undecided goes under Open Decisions with 2-3 options and a recommendation. Never fill a gap silently.
4. Milestones: thin end-to-end slice first (P10), then deepen. Each milestone states what to build, how to test, and what success means.
5. Every never-go-wrong item must map to at least one acceptance test.

### 1.3 When the owner asks "why"
Answer with: the constraint that drives it, the principle or decision ID, the main alternative, and what would make the alternative better.

---

## 2. Principles

- **P1. Fixed steps and hard rules are code.** If a step can be an if-statement, formula, or query, it is code. Thresholds, permissions, money limits, ownership checks, and routing rules are always code, even if a model could follow them. [Certain]
- **P2. The model handles judgment only:** language understanding, ambiguity, interpretation, synthesis, choosing among many unpredictable paths.
- **P3. The model proposes; code executes.** The model never directly calls tools that move money, delete data, send external messages, or change production. It returns a structured decision. Code validates and executes.
- **P4. Identity comes from the session.** User, customer, and tenant IDs are injected by code. Never a model-supplied argument.
- **P5. Every external call goes through one wrapper:** input validation, timeout, retry with backoff, structured errors, logging.
- **P6. Every write that can be retried is idempotent** (idempotency keys, unique event IDs, dedupe on request IDs). Exactly-once delivery is not achievable in practice. [Certain]
- **P7. Waiting is a stored state, not a running loop.** Anything that waits on a human, an external event, or a retry is persisted and resumed by an event, with an expiry.
- **P8. Structured output is validated twice:** schema (shape) and semantic checks in code (values make sense against real data).
- **P9. External text is data, not instructions.** Customer messages, web pages, documents, emails, logs, and tool output can contain prompt injection. Safety comes from code gates, not prompt wording.
- **P10. Build a thin end-to-end slice first.** A working happy path with fakes beats complete layers that don't connect.
- **P11. Start simple; add complexity on evidence.** Rerankers, multi-agent, frameworks, and extra loops need a measured trigger (failing eval, latency, cost).
- **P12. Spend thinking on hard-to-reverse decisions:** data model, where state lives, security boundaries, embedding model of an index, external contracts. Default the easy-to-reverse ones.
- **P13. Every decision affecting money, access, or compliance is auditable** from stored records alone.
- **P14. Every never-go-wrong item has a test** that would fail if the rule were broken.

---

## 3. Constraint questions

Ask these before choosing anything. Each one drives specific decisions.

| ID | Question | Drives |
|---|---|---|
| C1 | What must never go wrong? | Gates, approvals, validation, tests (SF, EV) |
| C2 | How fast must the caller get a reply? | Model size, parallelism, streaming, sync vs async (MD, SV) |
| C3 | What volume, and what cost per task is acceptable? | Model tier, caching, batching, how much is code (MD) |
| C4 | What does the data look like? Size, structure, change rate, exact codes vs prose | Knowledge strategy, RAG design (KN) |
| C5 | Which steps are fixed and which need judgment? | Control flow (CF) |
| C6 | How long does one task live, including waiting? | State, durability, pause/resume (ST) |
| C7 | Who consumes the output: a person, a program, an auditor? | Structured output, audit, formatting (SO, OB) |

C2 and C6 differ: a task can reply in seconds (C2) but stay open for days waiting on approval (C6).

---

## 4. Control flow (CF)

### CF-1 Overall shape
- **Options:** workflow (code decides steps), agent (model decides steps), hybrid.
- **Choose:** steps known in advance → workflow. Steps depend on results → agent. Most real systems → hybrid.
- **Default:** code pipeline with a bounded agent loop only where judgment is needed. [Likely]

### CF-2 Pattern catalog
| Pattern | Use when | Avoid when |
|---|---|---|
| Single call | Classify, extract, rewrite | Needs external data or distinct stages |
| Prompt chain | Several model calls in a fixed order, each feeding the next | Next step depends on what a step discovers |
| Single call inside a code workflow | Only one step needs a model; the rest is code | Not a "chain" if only one model call exists |
| Router | Input types need different handling. Model classifies, code dispatches. Always include an "unknown → human" route. | One handler covers all types |
| Parallel sectioning | Independent subtasks you define in advance, run at once, merged by code | Subtasks depend on each other |
| Parallel voting | Discrete answer, single call not reliable enough, mistakes costly. Rule: majority for accuracy, "any flags it" for safety. Vary prompts or temperature for diversity. | Free-text output; code can verify instead; cheap mistakes at high volume |
| Orchestrator-workers | Subtasks unknown until runtime; model decides them. If code can find the subtasks (e.g. text search), use a code fan-out instead. | Subtasks known in advance (use sectioning) |
| Evaluator-optimizer | Clear pass criteria. Prefer code evaluators (tests, linters, exact checks); model critic only for what code can't check. Max rounds, then human. | No clear criteria |
| Agent loop (ReAct) | Path depends on results, step count unknown, short tasks | Steps always the same |
| Plan-and-execute | Long tasks (5+ steps), human should approve before risky work, progress tracking or resume needed, plan stable after initial look. Allow re-planning. | Short tasks; each result changes direction |
| Multi-agent | See MA | Default choice |

### CF-3 Loop controls (required on every agent loop)
Max turns, time budget, token/cost cap, loop detection (same call repeated 2-3 times), and a forced final tool with a schema.

### CF-4 Parallel tool calls
Independent calls run concurrently (`asyncio.gather`). Dependent calls happen across turns.

---

## 5. Tools (TL)

### TL-1 Granularity
- **Options:** one tool per API endpoint | task-shaped tools (code combines endpoints inside).
- **Default:** task-shaped, few tools. Fewer calls, fewer ID-passing mistakes, smaller results. [Likely]
- **Endpoint-level is fine when:** tasks vary unpredictably, or endpoints are few.
- **Omit** endpoints no task needs.

### TL-2 Tool count
- Past roughly 20-30 tools, add grouping, routing, or a tool-search step. [Guessing on the number]

### TL-3 Read vs write separation
- Never mix a lookup and a change in one tool. Combine within reads; keep each write separate and gated.
- An agent that reads untrusted content gets read tools only.

### TL-4 Arguments
- Identity and permission-scoping arguments are injected by code (P4).
- Validate arguments per tool with a schema before execution (hallucinated IDs are common).

### TL-5 Errors
- Catch exceptions in the wrapper and return a short structured result: `{"error": "<type>", "retryable": <bool>, "detail": "<safe message>"}`. Never return raw tracebacks to the model.

### TL-6 Shared executor
- One `run_tool(name, args)` for all tools. Same steps for every tool: validate, timeout, retry, error shape, log.
- Per-tool settings (input schema, timeout, retry count) live in a registry entry for each tool.

### TL-7 Descriptions
- Write tool descriptions like documentation for a new colleague: what it does, when to use it, when not to, example inputs.

### TL-8 MCP vs direct function
- **Direct function:** tool used only by this app. Default.
- **MCP server:** tool reused across multiple apps or clients (including ones you don't control, like desktop AI clients), maintained by another team, or required by the brief.

### TL-9 MCP transport
- **stdio:** server runs as a local subprocess on the same machine.
- **HTTP-based transport:** shared or remote server; needs hosting and auth. Check the current MCP spec for transport names.

### TL-10 MCP connection lifecycle
- **Default:** long-lived session, tools discovered once at startup, reconnect on failure.
- **Per request:** only when isolation matters more than latency.

### TL-11 Tool output trust
- Treat all tool output, especially from third-party servers, as untrusted data (P9).

### TL-12 Code execution tools
- Always sandboxed: limited network, resource limits, disposable environment.

---

## 6. Structured output (SO)

### SO-1 How to get structure
- **Options:** prompt instruction only | provider structured-output feature | forced tool call (`submit_*` tool as a form) | constrained decoding (self-hosted models).
- **Default:** provider feature or forced tool call. Prompt-only is least reliable. [Likely]

### SO-2 Validation
- Always validate with a schema (Pydantic). Then run semantic checks in code against real data (P8): amounts within limits, cited IDs actually provided, action allowed in current state.

### SO-3 Invalid output
- Retry once with the validation error appended, then escalate to a human. Never loop, never silently accept.

### SO-4 Field design
- Enums for decisions and categories. Integers for money (cents). Lists for citations. Small schemas.

### SO-5 Reasoning field
- Include a short reasoning field for audit and debugging. Code never branches on it.

---

## 7. Knowledge and RAG (KN)

### KN-1 Knowledge strategy
| Option | Choose when |
|---|---|
| Long context (+ prompt caching) | Corpus fits comfortably in context, changes rarely. Simplest. [Likely] |
| RAG | Corpus too large, grows, or chunk-level citations needed |
| Tool lookup (SQL/API) | Data is structured (orders, prices, inventory). Never embed rows to answer structured questions. |
| Fine-tuning | Teaching style, format, behavior. Poor for changing facts. [Likely] |

Combinations are normal: RAG for documents, tools for structured data.

### KN-2 Parsing
- Start with a simple local parser. Inspect output by hand, especially tables. Use layout-aware, vision-based, or OCR parsing only if inspection shows problems. Bad parsing can't be fixed downstream. [Certain]

### KN-3 Chunking
| Strategy | Choose when |
|---|---|
| Structure-aware (headings, sections) | Documents have clear structure. Enables "doc + section" citations. Default when headings exist. |
| Recursive splitting | Plain prose. Default otherwise. |
| Fixed size with overlap | Quick start, unstructured text |
| Semantic | Long prose without headings |
| Per-record | FAQs, products, tickets: one item per chunk |
| Parent-child | Match on small chunks, return the larger section |
| Contextual chunks | Chunks ambiguous out of context: prepend a short "where this sits" summary before embedding |

- Starting size: a few hundred tokens. Tune with retrieval evals, not intuition. [Likely]

### KN-4 Metadata
- Store source, page, section, date, version, and access scope on every chunk.
- **Access control is a retrieval filter, never a prompt instruction.** [Certain]

### KN-5 Embeddings
- **Options:** hosted APIs or local open models.
- **Choose:** privacy/offline/cost → local. Simplicity/quality → hosted.
- **Check:** language coverage, max input length, query vs document formatting requirements in the model card.
- Use public benchmarks to shortlist; decide on 20-50 of the owner's real questions.
- **Switching models requires re-embedding everything.** Treat as hard to reverse (P12).

### KN-6 Vector store
- **Default:** the database already in use (e.g. pgvector). At small scale the store barely matters. [Likely]
- Dedicated vector DBs: large scale, heavy filtering, many collections. In-memory: prototypes.
- Index: flat (exact) for small sets, HNSW for most larger sets, IVF for very large.

### KN-7 Keyword search and hybrid
- Use BM25-style keyword search when queries include exact codes, IDs, names, or legal terms.
- Merge vector and keyword results with Reciprocal Rank Fusion (k=60) by default. Weighted blends only with evals to tune them.

### KN-8 Reranking
- Retrieve 20-50, rerank with a cross-encoder, keep top 3-8.
- **Default:** none until evals show the right chunk is retrieved but ranked too low.

### KN-9 Query handling
- Multi-turn chat: condense follow-ups into standalone questions before searching (usually essential).
- Other techniques (rewrite, multi-query, decomposition, HyDE, structured query building) only when evals show retrieval misses.

### KN-10 Retrieval pattern
- **Default:** single-shot retrieval.
- Agentic RAG (search as a tool) when questions need follow-up searches across documents.
- Graph-based retrieval only for relationship-heavy questions across many documents.
- Text-to-SQL for tabular answers, read-only access.

### KN-11 Grounding
- Instruct: answer only from provided chunks; say when the answer isn't there.
- Require citations by chunk ID. Verify in code that cited IDs were provided. An unknown citation is a hallucination signal.

### KN-12 Freshness
- Define how updates and deletes reach the index. Version the corpus and record the version used per answer.

### KN-13 RAG evaluation
- Evaluate retrieval (recall@k, MRR) separately from generation (faithfulness, citation correctness), so failures can be located.

---

## 8. Context and memory (CX)

- **CX-1 Ordering:** stable content first (system prompt, tools, static docs), changing content last, to benefit from prompt caching.
- **CX-2 Tool results:** trimmed and structured. Never dump large raw responses into context.
- **CX-3 Conversation memory:** short chats → full history. Long chats → structured facts + rolling summary + last few turns. Default for multi-session.
- **CX-4 Long-term memory:** start with the app's own database tables. Memory frameworks only when needed.
- **CX-5 Isolation:** every memory read is scoped by user/tenant in the data layer (P4). Never rely on the prompt.
- **CX-6 What to store:** explicit facts the user stated. Be careful with inferences. Make memory correctable.
- **CX-7 Long runs:** compact old steps, offload notes to files or the database, or use subagents for context isolation.
- **CX-8** Very long contexts can degrade quality; more context is not automatically better. [Likely]

---

## 9. State and long-running work (ST)

- **ST-1 Execution style:** seconds → synchronous. Minutes → background job. Hours/days with waits → database state machine or durable workflow engine.
- **ST-2 State location:** anything that must survive a crash lives in the database, not in memory or model context.
- **ST-3 Many items:** job table with one row per item and a status (pending, done, failed), attempts, error. Restart skips done items.
- **ST-4 Orchestration tool:** **default** DB state machine + simple worker for small scope. Task queues for background jobs. Durable execution engines when there are many steps, timers, and complex retries. Framework checkpoints only if already using that framework.
- **ST-5 Transitions:** one function validates allowed transitions, uses optimistic locking (version column), and writes the audit event in the same transaction. Illegal transitions raise errors.
- **ST-6 Resume triggers:** events/webhooks first, polling as backup. Every wait has an expiry and a defined outcome. Never auto-approve on timeout.
- **ST-7 Concurrency:** explicit limits for external rate limits and cost.
- **ST-8 Check-then-act races:** if a decision depends on a check (e.g. "not shipped yet") and the action happens later, the action must be atomic on the system that owns the state (e.g. "cancel if not shipped"), or re-checked at execution time.
- **ST-9 Cached data:** any fallback to cached data carries a timestamp and a freshness rule. Non-terminal states need fresh data before irreversible actions; terminal states (e.g. delivered) can be used at any age.

---

## 10. Multi-agent (MA)

- **MA-1 Default:** single agent. Move to multi-agent only when a measured limit appears.
- **MA-2 Choose multi-agent when:** work splits into independent parts each needing its own multi-step tool investigation; one context can't hold the material; parts need different permissions.
- **MA-3 Avoid when:** steps depend closely on each other; one consistent shared state is needed; tight budget; single agent untried.
- **MA-4 Not the same as a router.** A router picks one handler per input. Multi-agent means several agents cooperate on one task.
- **MA-5 Subagent output:** compact structured results, not transcripts. Large shared data goes in a shared store.
- **MA-6 Failures:** accept partial results with a coverage report.

---

## 11. Safety, guardrails, human-in-the-loop (SF)

### SF-1 Action risk tiers
| Tier | Examples | Gate |
|---|---|---|
| Read | Search, lookup, summarize | Scope by user; usually no approval |
| Reversible write | Draft, ticket, note | Logging, maybe confirmation |
| Irreversible/costly | Money, deletion, external messages, deploys, production rollback | Code-enforced limits, approval, idempotency, audit |

### SF-2 Prompt injection
- No complete prompt-level fix exists. [Likely] Defend by: delimiting and labeling external text, least privilege for agents reading untrusted content, code gates on high-risk actions, output validation.

### SF-3 Human-in-the-loop styles
- Approve before action (irreversible), review after (low risk, high volume, sampled), escalation queue, confidence-based routing.
- Approvals are stored records with an approver identity and an expiry.

### SF-4 Defense in depth for thresholds
- A rule like "amounts ≥ X need approval" is enforced at routing **and** inside the action itself (the action refuses without a matching approval).

### SF-5 Data handling
- Redact personal data in logs and traces. Secrets in environment variables, never in prompts or logs.

### SF-6 Permissions
- Least privilege per tool and per agent. Read-only database roles where possible.

---

## 12. Reliability (RL)

- **RL-1 Timeouts** on every external call. [Certain]
- **RL-2 Retries:** exponential backoff with jitter, only for retryable errors (timeouts, rate limits, server errors). Never blindly retry client errors.
- **RL-3 Circuit breaker** when a dependency fails often and retries pile up.
- **RL-4 Fallbacks** in order: cached data (with freshness rule, ST-9), alternate source/provider/model, degraded answer, human or retry-later queue. Never guess missing facts.
- **RL-5 Budgets** on agent loops: turns, time, tokens, cost.
- **RL-6 Dead-letter handling:** failed items are kept for review, never dropped.
- **RL-7 Partial results** with a coverage note for research-type tasks.
- **RL-8 LLM-specific failures:** invalid output (SO-3), hallucinated arguments (TL-4), refusals (route to human), repeated calls (CF-3), provider outage (retry, optional fallback model, queue).

---

## 13. Models, cost, latency (MD)

- **MD-1 Cost formula:** `requests/day × calls/request × (input tokens × input price + output tokens × output price)`. Estimate it before choosing a model. Use current provider prices.
- **MD-2 Levers:** move steps to code; trim context; prompt caching; smaller model for easy steps; batch APIs for non-urgent work; parallel calls (latency only); streaming (perceived latency only).
- **MD-3 Tier:** start mid-tier, test smaller. Larger only for judgment-heavy steps that fail evals.
- **MD-4 Routing:** one model first. Route or cascade (small first, escalate if unsure) at high volume with mixed difficulty.
- **MD-5 Temperature:** low for decisions and extraction.
- **MD-6 Hosting:** API by default. Self-host for strict data rules, very high volume, or offline needs.
- **MD-7 Pin model versions.** Re-run evals on any model change. [Certain]

---

## 14. Observability (OB)

- **OB-1 Four separate layers:** audit log (permanent, append-only, compliance), traces (one request end to end), metrics (trends and alerts), logs (debug events). Audit is mandatory when decisions affect money, access, or compliance (P13).
- **OB-2 Capture per model call:** model ID, prompt version, redacted input/output, tokens, cost, latency.
- **OB-3 Capture per tool call:** name, arguments, result or error, attempts, latency.
- **OB-4 Capture for RAG:** retrieved chunk IDs and corpus version.
- **OB-5 Backend:** OpenTelemetry instrumentation into one LLM-aware backend, or structured logs plus a database table for small projects.
- **OB-6 Alerts:** safety violations (must be zero), error rates, fallback rates, cost spikes, stuck tasks.

---

## 15. Evals (EV) and serving (SV)

### Evals
- **EV-1 Layers:** unit tests for code rules; retrieval evals; scenario (end-to-end) evals; trajectory checks (right tools, forbidden calls absent); LLM-as-judge for quality only; safety/injection scenarios; failure injection with fake services.
- **EV-2 Start with 20-30 cases:** normal, edge, and never-go-wrong cases. Add every real failure and human override as a new case. [Likely]
- **EV-3 Non-determinism:** run cases N times, report pass rates. Hard rules require 100%.
- **EV-4 Graders:** prefer exact and rule-based checks. LLM judges need a rubric and calibration against human labels. Never use a judge for a rule code can check.
- **EV-5 Gating:** block on hard-rule failures, warn on quality drops.
- **EV-6 Default harness:** pytest with scripted fake services.

### Serving and frameworks
- **SV-1 Response style:** under ~30s → synchronous. Longer → async job (return ID, poll or callback). Chat UI → streaming.
- **SV-2 Sessions:** stateless unless multi-turn; multi-turn uses a session ID with server-side history.
- **SV-3 Hosting:** containers for agent loops; serverless time limits can cut long runs. [Likely]
- **SV-4 Frameworks:** default to the raw provider SDK and an explicit loop, so decisions stay visible. Adopt a framework only for a named feature it provides (durable checkpoints, many connectors).

---

## 16. Red flags (check every design against these)

| ID | Red flag | Fix |
|---|---|---|
| RF-1 | Agent used for a fixed sequence | Workflow in code (CF-1) |
| RF-2 | Business rule enforced only in the prompt | Move to code (P1) |
| RF-3 | Model calls a money-moving, destructive, or external-messaging tool directly | Model proposes, code executes (P3) |
| RF-4 | Model supplies user/customer/tenant ID | Inject from session (P4) |
| RF-5 | A "tool" that returns a yes/no for a rule code could compute | Make it a code function that returns a route (P1) |
| RF-6 | Verification or lookup done as a model tool call on every request | Fixed code step (P1) |
| RF-7 | Cached or fallback data used for irreversible actions with no freshness rule | Timestamp + freshness rule (ST-9) |
| RF-8 | Check now, act later, with no atomic action or re-check | Atomic action on owning system (ST-8) |
| RF-9 | Waiting inside a running loop | Stored state + resume handler (P7) |
| RF-10 | Wait with no expiry, or auto-approve on timeout | Expiry with a defined, safe outcome (ST-6) |
| RF-11 | Retried writes without idempotency | Idempotency keys (P6) |
| RF-12 | Raw exceptions returned to the model | Structured errors (TL-5) |
| RF-13 | Read and write mixed in one tool | Separate (TL-3) |
| RF-14 | No loop limits | CF-3 |
| RF-15 | Valid JSON trusted without semantic checks | P8 |
| RF-16 | Access control in the prompt | Retrieval/data-layer filter (KN-4, CX-5) |
| RF-17 | Structured data embedded for RAG instead of queried | Tool lookup (KN-1) |
| RF-18 | Embedding or chunking chosen without retrieval evals | KN-5, KN-13 |
| RF-19 | Multi-agent as the first design | MA-1 |
| RF-20 | No audit trail where money, access, or compliance is involved | P13, OB-1 |
| RF-21 | Observability or evals named but not specified | Specify what is captured and what is tested (OB, EV) |
| RF-22 | Never-go-wrong items with no test | P14 |
| RF-23 | Failure path ends in "error" for a normal business case (e.g. mismatch) | Route to a human queue with a reason |
| RF-24 | External text (customer, web, docs, tool output) treated as instructions | P9, SF-2 |
| RF-25 | Layer-by-layer build plan with no working slice early | P10 |

---

## 17. Output templates

### 17.1 Architecture review format

```
VERDICT: <score>/10. <Biggest flaw in one sentence, or "Sound." if none.>

ASSUMED CONSTRAINTS: <C1-C7 values you assumed, and questions for unknowns that change the design>

SCORES (only areas the design touches):
| Area | Score | One-line reason |

WHAT'S WRONG (ordered by severity):
1. <Problem>. Violates <ID>. Fix: <change>. [confidence]

WHAT'S MISSING:
- <Item>. Needed because <constraint/ID>.

WHAT'S RIGHT (one line each, no praise):
- <Decision> fits because <reason>.

REVISED FLOW:
<numbered steps, each marked (code) or (model)>

OPEN QUESTIONS FOR THE OWNER:
- <Only questions whose answer changes the design>
```

### 17.2 SPEC.md template (1-2 pages, human-readable)

```
# <Project>: SPEC

## Goal
<2-3 sentences.>

## Never go wrong
1. ...  (3-5 items; each maps to a test)

## Constraints
<C1-C7 values, one line each>

## Architecture
<Numbered flow, each step marked (code) or (model). Note parallel and pause/resume points.>

## Locked decisions
| # | Decision | Reason |

## Open decisions
| # | Decision | Options | Recommendation | Needed before |

## Milestones
| # | Build | Test | Success means |
(M1 = thin end-to-end slice with fakes)

## Assumptions to confirm
- ...
```

### 17.3 Decision record (append to DECISIONS.md)

```
D<n>: <Decision>
Constraint: <C1-C7>
Options: <2-3>
Choice: <picked>
Reason: <one sentence>
Reversible: <easy/hard, cost of switching>
Revisit when: <signal>
Replaces: <D# or none>
```

---

## 18. Time-boxed builds (about 3 hours)

- Thin slice first (P10): full happy path with fakes for every external service.
- Keep: never-go-wrong rules and their tests, structured output with validation, the tool wrapper, an audit table.
- Defer: reconciliation polling, rerankers, real webhook signature handling, multi-agent, observability backends, large eval suites.
- If time runs out, cut feature depth, never the safety tests.
