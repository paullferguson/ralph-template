# ISSUES

Open GitHub issues for this repo are provided at the start of context (fetched via `gh issue list` / `gh issue view`). Each issue is shown as `--- #<number> <title> ---` followed by its body.

You've also been passed the last 10 RALPH commits (SHA, date, full message). Review these to understand what work has been done.

# TASK BREAKDOWN

Break down the PRD into tasks.

Make each task the smallest possible unit of work. We don't want to outrun our headlights. Aim for one small change per task.

# TASK SELECTION

Pick the next task. Prioritize tasks in this order:

1. Critical bugfixes
2. Development infrastructure
3. Integration points between modules
4. Architectural decisions and core abstractions
5. Unknown unknowns and spike work

Getting development infrastructure like tests and types and dev scripts ready is an important precursor to building features.

6. Tracer bullets for new features

Tracer bullets comes from the Pragmatic Programmer. When building systems, you want to write code that gets you feedback as quickly as possible. Tracer bullets are small slices of functionality that go through all layers of the system, allowing you to test and validate your approach early. This helps in identifying potential issues and ensures that the overall architecture is sound before investing significant time in development.

TL;DR - build a tiny, end-to-end slice of the feature first, then expand it out.

7. Standard features and implementation
8. Polish and quick wins
9. Refactors

Fail fast on risky work. Save easy wins for later.

If there are no more tasks, emit <promise>NO MORE TASKS</promise>.

# SIZE

Keep changes small and focused:

- One logical change per commit
- If a task feels too large, break it into subtasks
- Prefer multiple small commits over one large commit
- Run feedback loops after each change, not at the end
  Quality over speed. Small steps compound into big progress.

# EXPLORATION

Explore the repo and fill your context window with relevant information that will allow you to complete the task.

# EXECUTION: RED

Where suitable, first write tests that fail because the feature is not yet implemented.

Run the tests to check that they fail using `npm run test`.

Tests should focus on the publicly accessible interface of the system. They should test user behavior, not internal implementation details.

# EXECUTION: GREEN

Next, implement the minimum amount of code necessary to make the tests pass.

# EXECUTION: REFACTOR

Finally, ALWAYS refactor the code to improve its structure. Don't just refactor the new code - look for opportunities to improve existing code as well.

Ensure the code adheres to best practices:

- Code is clear and readable
- Functions and variables are well-named
- No duplicated code
- Proper error handling
- No exposed secrets or API keys
- Input validation implemented
- Good test coverage
- Performance considerations addressed

If anything blocks your completion of the task, output <promise>ABORT</promise>.

# FEEDBACK LOOPS

Before committing, run ALL feedback loops:

1. TypeScript: `npm run typecheck` (must pass with no errors)
2. Tests: `npm run test` (must pass)
3. Lint: `npm run lint` (must pass)
   Do NOT commit if any feedback loop fails. Fix issues first.

# PROGRESS

After completing each task, append to progress.txt:

- Task completed and PRD item reference
- Key decisions made and reasoning
- Files changed
- Any blockers or notes for next iteration
  Keep entries concise. Sacrifice grammar for the sake of concision. This file helps future iterations skip exploration.

# COMMIT

Make a git commit. The commit message must:

1. Start with `RALPH:` prefix
2. Include task completed + PRD reference
3. Key decisions made
4. Files changed
5. Blockers or notes for next iteration

Keep it concise.

# THE ISSUE

If the task is complete, close the corresponding GitHub issue: `gh issue close <number>`.

If the task is not complete, add a progress comment: `gh issue comment <number> --body "Summary of what was done and what remains."`

# FINAL RULES

ONLY WORK ON A SINGLE TASK.
