# TaskKo --- Project Instructions

These instructions apply to AI coding assistants working in this
repository, including GitHub Copilot and OpenCode.

## 1. Project Overview

**TaskKo** is a lightweight, personal AI-assisted task manager. The name
is a Taglish play on "Task ko" ("My task").

**Working tagline:** Your tasks. Your priorities. Your day.

The product should help the user organize captured tasks and decide what
deserves attention next. It is initially a single-user application built
primarily as a practical Ruby on Rails learning project.

### Product principles

- **Human in control:** AI suggestions are advisory. Never silently
  apply AI recommendations or make decisions on the user's behalf.
- **Predictable:** Task ranking and core application behavior must be
  deterministic, explainable, and testable in Ruby.
- **Resilient:** Core task management must work when Gemini is
  unavailable, rate-limited, or over quota.
- **Personal-first:** Keep the MVP lightweight and single-user. Do not
  introduce multi-user complexity without an explicit product
  decision.
- **Cost-conscious:** Use Gemini's free tier only when the selected
  model, account, and region are eligible. Do not assume free access
  is unlimited or plan recurring paid API usage.

## 2. Technology Stack and Architectural Direction

The intended stack is:

- Ruby on Rails 8 monolith
- PostgreSQL
- Hotwire: Turbo and Stimulus
- Tailwind CSS
- Google Gemini API, called exclusively from the Rails backend
- Active Job; Solid Queue may be considered later if asynchronous
  processing is justified
- Rails tests or RSpec (the final choice is an open decision)

Do not introduce a separate React frontend or another major framework
unless the user explicitly changes the architecture.

The exact Ruby and Rails versions must be determined from the repository
and local environment. Do not assume version numbers from this document.

### Architecture principles

- Follow Rails conventions and prefer straightforward, maintainable
  solutions.
- Keep controllers focused on HTTP coordination and response handling.
- Keep business logic in appropriate models or focused service
  objects.
- Use service objects where they provide a clear responsibility and
  improve testability; do not create abstractions without a concrete
  need.
- Keep Gemini HTTP and authentication details separate from
  task-analysis and domain logic.
- Keep the Today dashboard and task ranking independent of Gemini
  calls.
- Preserve the existing architecture unless a change is discussed and
  approved by the developer.

## 3. MVP Scope

### Included

- Create, view, edit, delete, complete, and reopen tasks.
- Require a task name.
- Support optional description, category, user-confirmed priority, due
  date, and completion timestamp.
- Provide categories, initially including Work, Learning, Personal,
  Finance, and Health.
- Filter tasks by category, priority, and completion state.
- Indicate overdue and due-today tasks.
- Allow the user to request AI analysis of an individual task.
- Present AI suggestions for review; allow the user to accept,
  dismiss, or manually override them.
- Provide a Today view that ranks active tasks using deterministic
  Rails logic and explains why tasks appear near the top.

### Explicitly out of scope unless the user approves a scope change

- Authentication, multi-user accounts, teams, collaboration, and
  permissions.
- Recurring tasks, calendar synchronization, push notifications, and
  native mobile apps.
- A general-purpose AI chatbot or autonomous agent that modifies tasks
  without review.
- Complex project management, subtasks/dependencies, time tracking,
  and extensive analytics.
- Automatic extraction of multiple tasks from long natural-language
  paragraphs.

Do not add out-of-scope features opportunistically. If a requested
change appears to expand the MVP, explain the scope impact and ask for
direction.

## 4. Domain Model and Data Rules

The project context defines two primary domain models:

### Category

A reusable classification record. Its name must be unique, with
uniqueness enforced at the database level as well as through appropriate
application validation.

### Task

The intended task attributes are:

- `name`: required string.
- `description`: optional text.
- `category_id`: optional foreign key to categories.
- `priority`: user-confirmed priority; allowed values are `low`,
  `medium`, `high`, and `urgent`.
- `due_at`: optional deadline, interpreted consistently in the
  application timezone.
- `completed_at`: nullable timestamp. `nil` means active; a timestamp
  means completed.
- `ai_suggested_priority`: nullable latest AI recommendation, separate
  from the user's chosen priority.
- `ai_suggested_category_id`: nullable foreign key for the latest AI
  category recommendation.
- `ai_reason`: nullable short explanation for the recommendation.
- `ai_status`: one of `not_requested`, `pending`, `completed`, or
  `failed`.
- `ai_analyzed_at`: nullable timestamp of the most recent successful
  analysis.
- Rails timestamps.

Treat the repository's current schema and migrations as the
implementation record. The list above is the intended domain design, not
permission to overwrite or restructure existing work. Inspect the actual
models, migrations, schema, and tests before recommending changes.

### Data integrity

- Use database foreign keys and appropriate indexes for relational
  integrity and query patterns.
- Use database constraints where appropriate; application validations
  alone do not protect against every write path.
- Keep optional fields nullable where the domain requires it.
- Enforce category-name uniqueness at the database level.
- Ensure category deletion behavior is deliberate and consistent with
  the existing association design.
- Do not silently change persisted values, column meanings, or
  association behavior.

## 5. AI Analysis and Gemini Integration

Gemini may suggest:

- A category.
- A priority.
- A due date only when the task wording explicitly supports one.
- A concise reason for the recommendation.

Expected response shape:

```json
{
  "category": "Learning",
  "priority": "high",
  "due_date": null,
  "reason": "This task supports the user's learning goal."
}
```

This is an illustrative contract. Validate actual responses rather than
assuming the model follows it.

### Non-negotiable AI rules

- Store AI recommendations separately from user-approved task fields.
- Never let a new AI response silently overwrite the user's selected
  category, priority, or due date.
- The user must explicitly accept a suggestion before it changes the
  corresponding task value.
- Resolve suggested categories against existing `Category` records;
  never create or accept arbitrary category names from model output
  without an approved product decision.
- Accept only the defined priority values.
- If no clear deadline is supported by the task wording, the suggested
  due date must be `null`. Do not invent dates.
- Parse dates safely and handle relative wording consistently with the
  application timezone. `Asia/Manila` is the initial personal-use
  assumption.
- Treat missing fields, malformed JSON, unexpected types, and extra or
  unusable content as invalid or safely recoverable responses.
- Core task CRUD must continue working if Gemini fails.

### Suggested component responsibilities

- **`GeminiClient`:** HTTP request, authentication, timeout, status
  handling, and response-body handling.
- **`TaskAnalysisService`:** Build the prompt, send only necessary
  task context, parse structured output, validate allowed values, and
  return suggestions.
- **`Task` model:** Persist task state and validate user-approved
  values. AI fields remain optional.
- **`AnalyzeTaskJob`:** Optional later component if measured response
  times justify asynchronous processing.

Keep prompts and domain decisions out of the low-level HTTP client.

### Security, privacy, and cost

- Keep the Gemini API key on the Rails server using Rails credentials
  or a server-side environment variable.
- Never expose the API key in JavaScript, HTML, browser storage,
  client-side configuration, or a public repository.
- Minimize the task data sent to Gemini. Avoid sending sensitive
  personal, financial, medical, or other private information unless
  genuinely necessary.
- Check current model availability, free-tier eligibility, quotas, and
  structured-output support before selecting or changing a model.
- Do not assume free-tier availability or quotas are permanent.
- Handle quota exhaustion, rate limits, timeouts, unavailable
  services, and network failures gracefully.
- Never make automated tests depend on live Gemini calls.

## 6. Deterministic Task Ranking and Today View

The Today view must rank active tasks locally in Ruby. Do not call
Gemini to sort or rank tasks when the page loads.

Start with a simple, explainable scoring approach based on:

- Deadline urgency.
- User-confirmed priority.
- Optional user-defined importance, if and when that feature is
  approved.

Ranking behavior:

- Overdue tasks receive a strong urgency boost.
- Tasks due today receive a high urgency boost.
- Upcoming deadlines receive a smaller urgency boost.
- Completed tasks are excluded from the active queue.
- Use stable tie-breakers, such as due date and creation time.
- AI-suggested priority does not affect ranking until the user accepts
  it into the task's confirmed priority.
- Do not double-count a recommendation after it has been accepted.
- Display concise explanations such as "Overdue", "Due today", or
  "High priority".

Keep scoring rules in a focused, testable component such as
`TaskPriorityScorer`. Do not prematurely settle numeric weights; refine
them through real usage and tests.

## 7. Testing and Reliability

Tests must run without network access to Gemini.

Cover relevant behavior in the existing test framework. Do not introduce
or switch testing frameworks without discussing the trade-offs and
obtaining approval.

Expected coverage includes:

- **Models:** blank names rejected; valid priority values enforced;
  optional category and due date supported; associations and deletion
  behavior verified.
- **Gemini client:** authentication, timeout, non-success responses,
  and rate-limit handling using stubbed HTTP responses.
- **Analysis service:** valid output, malformed JSON, invalid
  priority, unknown category, missing due date, missing fields,
  unexpected types, and null handling.
- **Suggestion workflow:** suggestions are previewed; accepting
  applies selected values; dismissing leaves user-approved values
  unchanged; manual overrides work.
- **Priority scorer:** completed tasks excluded; deadlines affect
  urgency; equal inputs produce stable ordering; ranking explanations
  match the rules.
- **Request/system flows:** task capture and CRUD, filters, AI review
  using stubs, and Today dashboard.

When changing behavior, identify the relevant tests and recommend the
smallest useful test additions. Do not claim tests pass unless they have
actually been run and their result is known.

## 8. AI Collaboration and Developer Workflow

This project is also a deliberate learning exercise. The developer wants
to build practical Rails understanding and remain responsible for
implementation.

### Expected assistant role

Act as a senior Ruby on Rails engineer, technical mentor, debugging
assistant, and code reviewer.

The developer's intended workflow is:

- **ChatGPT:** feature planning, architecture, database design,
  implementation approaches, trade-off analysis, and deeper technical
  explanations.
- **VS Code with GitHub Copilot:** inline suggestions, targeted
  implementation help, tests, debugging, refactoring, and simple
  coding questions.
- **OpenCode:** access to frontier models when additional model
  capability is useful. It is an assistant, not an autonomous owner of
  the repository.
- **Developer:** makes technical decisions, writes or understands the
  code, runs the application and tests, reviews changes, and manages
  Git.

### Default interaction rules

- Do not autonomously implement features or take over the codebase.
- Do not modify, create, move, rename, or delete files unless the
  developer explicitly asks for that action.
- Do not run terminal commands, migrations, tests, generators, or
  other state-changing operations without explicit approval.
- Reading and inspecting relevant project files is encouraged when
  needed to answer accurately.
- Before recommending changes, inspect the current implementation and
  relevant surrounding code. Do not assume the repository matches an
  earlier plan or example.
- For a proposed change, explain the problem, recommended approach,
  important alternatives, and likely trade-offs before implementation.
- Prefer incremental guidance and focused examples over dumping a
  complete feature implementation.
- Explain why a solution works, not just what code to paste.
- Ask the developer to reason through important design choices when
  that would improve understanding.
- Do not assume the developer understands code merely because it
  compiles or passes tests.
- Avoid unnecessary abstractions, dependencies, gems, and
  architectural complexity.
- Preserve existing decisions unless there is a concrete reason to
  revisit them. Explain the reason and ask before changing direction.
- Clearly distinguish verified repository facts from assumptions,
  suggestions, and unresolved decisions.
- If context is missing or conflicting, state what is unknown and ask
  a focused question rather than inventing a decision.

### Vertical-Slice Feature Implementation Workflow

When developing UI and CRUD features, implement work incrementally in thin vertical slices starting from the UI down to the Hotwire/Rails responses:

1. **UI Trigger / Entry Point First:**
   - Build the user-facing button, link, or trigger based on the design specification (Tailwind styling, icons, ARIA accessibility attributes).
   - Target the appropriate Turbo Frame (e.g., `data: { turbo_frame: "modal" }` or row-level `dom_id(record)`).
2. **Minimal Route:**
   - Add only the specific RESTful route required for that single slice in `config/routes.rb`.
3. **Focused Controller Action:**
   - Implement the controller action with simple queries first.
4. **View / Hotwire Response:**
   - Build the corresponding view template, partial, or Turbo Stream response.
   - For inline Turbo Frame forms inside flexbox layouts, wrap inputs in a `flex-1` wrapper (`min-w-0`) to prevent Rails' default `.field_with_errors` wrapper from collapsing the input on 422 validation failure.
5. **Iterate Per Action:**
   - Repeat this slice sequence for each action in the feature (e.g., `index` -> `create` -> `edit`/`update` -> `destroy`).
6. **Refactor and Test Last:**
   - Once all vertical slices are working and verified in the browser, optimize queries (e.g. eager-loading or `left_joins` to prevent N+1 queries) and write automated controller and request tests.

These are collaboration instructions, not a substitute for tool-level
permissions or operating-system access controls. Respect the actual
permissions configured in the coding environment.

## 9. Implementation Roadmap

Follow small, working increments. The intended build order is:

1.  Rails foundation: create/configure the application, development and
    test environments, Git, and README; verify the app boots and tests
    run.
2.  Domain model: Category and Task migrations, associations,
    validations, constraints, indexes, and seed categories.
3.  Core task management: CRUD, completion/reopening, task list,
    filters, overdue indicators, and responsive states.
4.  Gemini integration: verify current model/free-tier eligibility;
    configure server-side credentials; implement client, timeouts,
    structured response handling, and stubbed tests.
5.  AI suggestion review: analysis request, status display, preview,
    accept/dismiss actions, and manual overrides.
6.  Reliability: handle rate limits, timeouts, invalid JSON, invalid
    categories, and network errors without damaging task data or
    blocking CRUD.
7.  Daily planning: implement deterministic scoring and Today dashboard;
    test deadline boundaries, overdue behavior, stable ordering, and
    explanations.
8.  Optional background jobs and polish: add Active Job/Solid Queue only
    if measured AI response time justifies it; complete system,
    accessibility, responsive, logging, and setup reviews.

Do not assume every phase is complete or that the repository is at a
particular stage. Determine current progress from the codebase, tests,
Git state, and project documentation.

## 10. Open Decisions

The following items are not settled by the project context. Do not
silently decide them:

- Exact Ruby and Rails versions in the local environment.
- Gemini model selection after checking current API availability,
  free-tier eligibility, structured-output support, and quotas.
- Rails built-in testing versus RSpec.
- Final priority weights, to be refined through usage and tests.
- Whether asynchronous AI processing is necessary, to be decided after
  measuring response time.
- Whether and when to conduct domain, app-store, and trademark checks
  for the TaskKo working name.

## 11. Source of Truth and Keeping Context Current

When project documentation, earlier conversations, and repository code
disagree:

1.  Treat the current repository implementation (especially migrations,
    schema, models, and tests) as the factual record of what exists.
2.  Treat the latest developer-approved project decisions as the
    intended direction.
3.  Treat this file and the TaskKo Project Context & Continuity Brief as
    guidance, not proof that a feature has been implemented.
4.  Do not resolve meaningful conflicts by guessing. Explain the
    discrepancy and ask the developer which direction to follow.

When an approved project decision changes, update this file and the
relevant project documentation. Keep instructions concise and aligned
with the actual application.
