---
name: focused-execution
description: Prevent AI coding agents from wasting tokens on full-repository analysis, repeated verification, and reasoning loops. Use for implementation, debugging, refactoring, UI changes, configuration fixes, and codebase tasks where fast scoped execution is preferred.
---

# Focused Execution — Anti-Loop Coding Skill

## Mission

Complete the user's task with the **smallest necessary amount of repository inspection, reasoning, editing, and verification**.

The priority order is:

1. Understand the requested outcome.
2. Locate the smallest relevant scope.
3. Inspect only what is required.
4. Make the change.
5. Run targeted verification.
6. Stop.

Do **not** turn a small task into a repository-wide investigation.

---

## 1. Scope First

Before reading files, classify the task:

- **Single-file** → inspect that file first.
- **Known feature/module** → inspect only that module and its direct dependencies.
- **Build/config issue** → inspect the relevant config, error output, and directly referenced files.
- **UI change** → inspect the target screen/component, its parent layout, theme/style source, and directly related assets only.
- **Cross-cutting change** → expand scope only when evidence requires it.
- **Unknown issue** → start with the error, stack trace, failing command, or user-mentioned component.

Never begin by reading the entire repository.

### Default inspection budget

Start with:

- 1 target file
- up to 2 directly related files
- relevant configuration only if necessary

Expand the scope **only when the current evidence proves it is needed**.

---

## 2. Never "Analyze Everything"

Do NOT automatically:

- list every repository file
- open every source file
- read every README
- inspect every dependency
- inspect unrelated modules
- scan the whole git history
- analyze the complete architecture
- search the repository repeatedly for the same concept

If the task can be completed without those actions, do not perform them.

### Strong rule

> If a file is not plausibly involved in the requested behavior, do not open it.

---

## 3. Search Narrowly

Use targeted searches.

Good:

- exact error message
- exact function/class/widget name
- exact configuration key
- exact route/screen name
- exact dependency
- exact symbol referenced by the current file

Bad:

- searching every occurrence of generic words such as `app`, `data`, `config`, `build`, `error`
- searching the entire project for multiple speculative causes before inspecting the obvious target

After finding the likely location, stop searching unless evidence contradicts the hypothesis.

---

## 4. Act Early

Do not spend excessive time proving every possible cause before making a reasonable targeted change.

Use this loop:

```text
Understand → Inspect → Change → Verify → Stop
```

Not:

```text
Understand → Scan → Scan again → Research → Re-scan →
Speculate → Explain → Re-check → Re-analyze → Finally change
```

If the requested change is obvious and low-risk, implement it immediately after inspecting the relevant code.

---

## 5. Evidence-Based Expansion

Expand scope only when one of these occurs:

- the target imports a required symbol from another file
- the error originates elsewhere
- the change requires a shared interface/type
- a test fails and points to another component
- the build system explicitly reports another relevant file
- the first fix cannot work because of a discovered dependency

When expanding:

1. State internally why the new file is needed.
2. Inspect that file.
3. Return to the original task.
4. Do not restart repository analysis from zero.

---

## 6. Prevent Repeated Reads

Once a file has been sufficiently inspected, treat it as known.

Do not repeatedly reopen or re-read the same file unless:

- it was modified,
- new evidence changes the interpretation,
- a specific missing section must be checked.

Never perform the same search twice without a new reason.

---

## 7. Verification Budget

Verification must be proportional to the change.

### Tiny change
Examples:

- text
- spacing
- color
- one-line config
- import correction

Use:

- syntax/analyzer check if available
- targeted build/test only when useful

### Normal code change

Use:

- targeted test or analyzer
- relevant build command if practical

### Large or risky change

Use:

- targeted tests
- relevant build
- additional checks only when justified

Do NOT run the entire test suite merely because it exists.

---

## 8. Retry / Loop Protection

Never repeat the same failed command more than **2 times** without changing the diagnosis or approach.

If a command fails:

### Attempt 1
Inspect the actual error.

### Attempt 2
Make one evidence-based correction.

### If it still fails
STOP the loop.

Report:

- what was attempted
- the exact remaining blocker
- the smallest next action required

Do not keep trying random commands.

### Hard stop conditions

Stop investigation when:

- the task is completed
- targeted verification passes
- the same error remains after 2 meaningful attempts
- further inspection is speculative
- the next step requires information not available
- the user asked for a specific narrow change and it has been made

---

## 9. Avoid Speculative Fixes

Do not modify unrelated files "just in case".

Every changed file should have a clear reason connected to the task.

Before modifying a file, ask:

> "Can I explain in one sentence why this file must change?"

If not, don't change it yet.

---

## 10. Dependency Awareness Without Dependency Crawling

When encountering an import:

- inspect the imported definition only if its behavior matters to the task
- do not recursively inspect all imports
- stop once enough information exists to make the change safely

Example:

```text
Screen → Controller → API client → Database
```

If the task is only changing the Screen UI:

```text
Inspect Screen
Inspect Controller only if needed
STOP
```

Do not inspect API client and database code unless evidence requires it.

---

## 11. UI Tasks

For UI changes, prioritize:

1. target screen/component
2. parent layout
3. theme/design tokens
4. directly used assets
5. relevant animation code

Do not scan the entire design system unless the requested change actually depends on it.

Preserve existing:

- architecture
- color system
- typography
- spacing conventions
- responsive behavior
- performance characteristics

Avoid introducing a new library when the existing stack can achieve the result.

---

## 12. Configuration / Build Tasks

For build or environment errors:

Start from the **first meaningful error**, not the entire log.

Inspect in this order:

```text
Error → referenced file → relevant config → dependency/version → fix
```

Do not analyze unrelated warnings unless they prevent the build.

Do not upgrade packages, SDKs, Gradle, Java, Flutter, Node, etc. unless the evidence indicates a version incompatibility.

---

## 13. Preserve Existing Work

Before changing code:

- do not overwrite unrelated user changes
- do not reformat entire files unnecessarily
- do not refactor unrelated code
- keep diffs minimal

Prefer the smallest patch that correctly solves the task.

---

## 14. Token Efficiency Rules

Use concise internal reasoning and avoid generating large explanations when execution is the goal.

Prefer:

```text
Target found → cause identified → patch → verify
```

Avoid producing:

- full repository summaries
- repeated architecture explanations
- exhaustive alternatives
- speculative root-cause lists
- verbose code walkthroughs unrelated to the requested task

When showing results, report only:

- what changed
- files changed
- verification result
- blocker, if any

---

## 15. Do Not Ask Unnecessary Questions

If the task is sufficiently clear, execute it.

Ask a question only when:

- two interpretations would produce materially different changes
- a destructive action requires confirmation
- a required input is genuinely missing
- the requested behavior conflicts with existing requirements

Do not ask for permission to inspect obvious files or perform normal verification.

---

## 16. Completion Contract

A task is complete when:

- the requested behavior is implemented, OR
- the requested diagnosis is established, OR
- a concrete blocker prevents completion.

Then STOP.

Do not continue "improving" the solution unless the user asked for it.

---

## 17. Final Response Format

Keep the final response short.

Preferred:

```text
Done.

Changed:
- `path/to/file`: what changed
- `path/to/file`: what changed

Verified:
- `command`: result

If blocked:
- Blocker: exact reason
- Next action: smallest required action
```

Do not dump the entire analysis unless the user asks for it.

---

## Absolute Rules

These override normal agent habits:

1. **Never scan the whole repository by default.**
2. **Never repeatedly inspect the same files without new evidence.**
3. **Never repeat a failed approach more than twice.**
4. **Never modify unrelated files "just in case".**
5. **Never run broad tests when targeted verification is sufficient.**
6. **Never restart analysis from scratch after discovering new information.**
7. **Prefer execution over exhaustive speculation.**
8. **Stop immediately when the task is verified complete.**
9. **If blocked, report the blocker instead of entering a loop.**
10. **Minimize tokens, tool calls, file reads, and unnecessary output while preserving correctness.**
