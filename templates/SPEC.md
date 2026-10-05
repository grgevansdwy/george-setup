# <Project>: SPEC

> For the human. Keep to 1-2 pages. Detailed plans go in SPEC-DETAILED.md. Decision history goes in DECISIONS.md.

## 1. Goal
<2-3 sentences: what it does, for whom.>

## 2. Never go wrong
<3-5 items. Each one maps to at least one test.>
1.
2.
3.

## 3. Constraints
- **Response time:** <how long the caller waits for a reply>
- **Task lifetime:** <how long one task lives, including waiting>
- **Volume / cost:** <requests per day, acceptable cost per task>
- **Data shape:** <size, structure, change rate, exact codes vs prose>
- **Output consumer:** <person, program, auditor>

## 4. Big-picture decisions
| Decision | Choice | Reason | Ref |
|---|---|---|---|
| Language | | | D# |
| Framework | | | D# |
| Database | | | D# |
| Model | | | D# |
| Hosting | | | D# |

## 5. Flow

### 5.1 Per sub-problem
| Sub-problem | Approach (code / single call / ReAct / RAG / tool / MCP) | Why |
|---|---|---|
| | | |

### 5.2 End-to-end
<Numbered steps, each marked (code) or (model). Note parallel steps and pause/resume points.>
1. (code)
2. (model)
3. (code)

## 6. Safety rules
- **Gates and approvals:**
- **Permissions:**
- **Prompt-injection handling:**
- **Data handling:**

## 7. Open decisions
| Decision | Options | Recommendation | Needed before milestone |
|---|---|---|---|
| | | | |

## 8. Milestones
| # | Goal | Needs from you (API keys, MCP, data) | How to test | Success means |
|---|---|---|---|---|
| M1 | Thin end-to-end slice with fakes | | | |
| M2 | | | | |
| M3 | | | | |

## 9. Assumptions to confirm
-
