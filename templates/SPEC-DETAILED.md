# <Project>: SPEC-DETAILED

> For the coding agent.

## 0. How to use
- SPEC.md wins if this file conflicts with it.
- Follow BRAIN.md for architecture rules.
- Record every new choice in DECISIONS.md using its template.
- Build one milestone at a time: plan, build, test, stop for review.

## 1. Project structure
```
<folder and file layout>
```

## 2. Data model
<Tables or schemas, with fields and types.>

## 3. Interfaces

### 3.1 API endpoints
| Method | Path | Request | Response |
|---|---|---|---|
| | | | |

### 3.2 Tools
| Name | Read or write | Input schema | Output | Notes |
|---|---|---|---|---|
| | | | | |

### 3.3 Model output schemas
<Pydantic models or JSON schemas for every structured model output.>

### 3.4 External services
| Service | Interface | Fake for tests |
|---|---|---|
| | | |

## 4. Components
<One section per sub-problem.>

### 4.1 <Component name>
- **Inputs:**
- **Outputs:**
- **Code vs model:**
- **Prompt requirements:**
- **Validation (schema + semantic):**
- **Failure handling:**

## 5. State and flow
<Only if tasks are long-running.>
- **States:**
- **Allowed transitions:**
- **Pause/resume triggers:**
- **Expiries and their outcomes:**

## 6. Failure handling
| Failure | What happens |
|---|---|
| | |

## 7. Configuration
| Variable | Purpose | Default |
|---|---|---|
| | | |

## 8. Milestone plans

### M1: <name>
- **Files to create or change:**
- **Tests to write:**
- **Acceptance checks:**
- **Needs from human:**
- **Done when:**

### M2: <name>
- **Files to create or change:**
- **Tests to write:**
- **Acceptance checks:**
- **Needs from human:**
- **Done when:**

## 9. Test plan
- **Unit tests:** <code rules>
- **Scenario tests:** <full cases end to end>
- **Safety tests:** <never-go-wrong items, prompt injection>
- **Failure tests:** <fake services that fail on purpose>

## 10. Commands
- Run:
- Test:
- Migrate:
