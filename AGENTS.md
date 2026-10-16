# TMCEBMS — Workspace Agent Rules

Equipment Borrowing & Tracking Management System. This is a **parent/superproject**:
it tracks two independent applications as git submodules (no `.gitmodules` file —
they have their own repositories). Work inside the app the task concerns.

## Repository layout

| Path | Application | Stack |
|------|-------------|-------|
| `tmcebms/` | Mobile app (own git repo) | Flutter / Dart, `provider` |
| `tmc-ebm-system-web/backend/` | REST API | Laravel 12, PHP 8.2, MySQL, Sanctum, Reverb |
| `tmc-ebm-system-web/frontend/` | Admin web UI | React 19, Vite 7, React Router 7, Axios |

App-specific rules live in `tmcebms/AGENTS.md` and `tmc-ebm-system-web/AGENTS.md`
(loaded via `opencode.json`). Read the relevant one before editing that app.
This file holds rules shared by all apps.

## Operating rules

**Context & token efficiency**
- Search before reading: use `grep`/`glob` to locate the exact symbol, file, or
  line, then read only that file and the surrounding lines needed.
- Never scan or re-read the whole repository. Reuse facts already gathered in the
  session; do not rediscover the architecture each turn.
- Do not `cat` full build output, lockfiles, `node_modules`, `vendor`, or
  generated files. Expand investigation only when evidence is insufficient.
- Batch independent tool calls in one message. Avoid redundant commands.
- Keep tool output and final answers short.

**Analyze, then change**
- Find the root cause before implementing; state the cause and the fix.
- Prefer minimal, focused edits that reuse existing widgets/components, services,
  models, hooks, and utilities. Do not add dependencies or refactor unrelated code.
- Match existing naming, formatting, and structure. Add no comments unless the
  surrounding code already uses them.

**Protect the user's work**
- The submodules contain uncommitted local changes. Never discard, overwrite, or
  revert them; read the current file state before editing.
- Do not change unrelated functionality. Do not run destructive DB operations,
  rewrite history, or make irreversible changes without explicit approval.

**Security**
- Never hardcode or log credentials, tokens, API keys, or production DB details.
  Keep secrets in `.env` files (git-ignored).
- Validate input and enforce authorization on the server.
- Use parameterized queries / Eloquent; never concatenate SQL strings.

**Verify before claiming success**
- Run the targeted formatter, analyzer/linter, test, and build for the app you
  touched (see that app's `AGENTS.md`). Do not re-run a check that already passed.
- Distinguish pre-existing failures from ones you introduced. Never report a check
  as passing unless it actually ran and passed.

**Report concisely**
- End with: files changed (with purpose), exact verification commands and results,
  and any unresolved issues or follow-ups.
