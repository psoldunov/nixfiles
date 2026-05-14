---
name: code-review
description: >
  Perform deep architectural code reviews of existing codebases, identifying structural problems
  and offering concrete improvement suggestions. Use this skill whenever a user wants to review
  existing code, audit a codebase, identify architectural smells, refactor modules, improve
  abstractions, or asks about whether their code is well-structured. Trigger on phrases like
  "review my code", "look at my codebase", "is this good architecture", "how can I improve this",
  "refactor suggestions", "code quality", "module design", "is this too shallow", or any request
  to analyse the structure or quality of a set of files. Also trigger when a user pastes or
  uploads code and asks "what do you think?" or similar open-ended quality questions. When in
  doubt, use this skill — a structured review is almost always better than an ad-hoc one.
---

# Code Review Skill

A skill for performing structured architectural code reviews, focused on module design quality,
abstraction depth, cohesion, and actionable refactoring suggestions.

---

## Core Philosophy

This review is grounded in **John Ousterhout's *A Philosophy of Software Design*** principles,
particularly the distinction between **deep** and **shallow** modules. The goal is not just to
point out bugs or style issues, but to identify whether the code's *structure* is working for or
against the developer.

Key concepts to apply:
- **Deep modules**: small interface, large implementation. Hide complexity well.
- **Shallow modules**: large interface relative to implementation. Leaky abstractions that force
  callers to know too much.
- **Information hiding**: Does each module hide its implementation details? Can it change
  internally without breaking callers?
- **Cognitive load**: Does the structure reduce or increase the mental effort to work in this
  codebase?

---

## Review Process

### Step 1: Orient

Before reviewing individual files, get the lay of the land:
- Ask for (or explore) the directory structure
- Identify the tech stack and language(s)
- Note the project type (API, frontend, library, CLI, full-stack, etc.)
- Ask what the user's main concerns are, if not already stated
- Look at entry points (main files, index files, route definitions)

If the user has uploaded files or pasted code, start there. If they've described a codebase,
ask them to share the relevant parts or a tree output.

### Step 2: Catalogue the modules

For each significant module/file/class/function cluster, identify:
- **Name and stated purpose**
- **Interface size**: How many public methods/exports/props does it expose?
- **Implementation complexity**: How much does it actually do?
- **Dependencies**: What does it import/require? What imports it?

Use this to classify each module as:
- ✅ **Deep**: Does a lot behind a simple interface
- ⚠️ **Shallow**: Thin wrapper, pass-through, or over-exposed internals
- 🔴 **Leaky**: Forces callers to know about implementation details

### Step 3: Identify smells

Look for these specific patterns (see `references/smells.md` for full catalogue):

**Module depth smells:**
- Pass-through functions that just delegate without adding value
- Modules that are just re-exports of other modules
- Classes/objects where every private thing has a getter
- Utility files that are just bags of unrelated functions

**Cohesion smells:**
- Modules that do two unrelated things (violates single-responsibility)
- Functions that take a boolean flag to switch between two distinct behaviours
- Files named `utils`, `helpers`, or `misc` that have grown beyond ~3 functions

**Interface smells:**
- Functions with 4+ positional parameters (should likely be an options object)
- Functions that return different types depending on input
- Callers that need to call 3+ methods in a specific order to use a module correctly

**Coupling smells:**
- Modules that import from many other modules in the same layer
- Circular dependencies
- Business logic bleeding into framework/infrastructure code (e.g. DB queries in route handlers)

### Step 4: Produce the review

Structure your output as follows:

---

#### 🗺️ Overview
Brief summary of what the codebase does, its structure, and overall impression.

#### 📊 Module Depth Scorecard
A table or list rating each major module/file as Deep / Shallow / Leaky, with a one-line reason.

#### 🔍 Key Issues (prioritised)
For each significant issue:
- **What**: What is the problem
- **Where**: File/function/line
- **Why it matters**: The concrete cost (cognitive load, brittleness, coupling, etc.)
- **How to fix**: A concrete suggestion, ideally with a before/after code snippet

Order issues by impact, not by file order. Lead with architectural issues, not style nits.

#### ✅ What's working well
Call out patterns done right. This is not just politeness — it helps the user know what to
*preserve* during refactoring.

#### 🏗️ Refactoring Roadmap (optional, for larger codebases)
If the issues are significant, suggest a sequenced plan:
1. Quick wins (low effort, high clarity gain)
2. Module merges or splits
3. Interface redesigns
4. Larger architectural changes

---

## Tone & Style

- Be direct and specific. "This is a shallow module" is more useful than "consider simplifying".
- Always explain *why* something is a problem in terms of its real cost to the developer.
- Avoid moralising. Don't say "you should always...". Say "in this case, X would reduce Y".
- Match the depth of the review to the codebase size. A 50-line utility file gets a lighter
  touch than a 20-file API server.
- If the code is in good shape, say so clearly and briefly. Don't invent problems.

---

## Language/Framework-Specific Notes

### TypeScript / JavaScript
- Check for `any` types used to paper over design problems
- Watch for React components that are doing data fetching + rendering + business logic
- In Next.js: are Server Components being used appropriately, or is everything a Client Component?
- Check if API route handlers are thin (just parse request → call service → return response)
- Excessive use of `useEffect` for things that could be derived state is a cohesion smell

### General
- If tests exist, check if they test behaviour or implementation. Implementation tests = tight
  coupling to internals = fragile.
- Check if error handling is consistent or ad-hoc across modules.

---

## Interaction Patterns

**If the codebase is large**: Ask the user which areas concern them most, or which files/modules
are most actively worked on. Don't try to review everything — focus depth on what matters.

**If the user wants to go deep on one file**: Do a line-by-line review using the smells catalogue
in `references/smells.md`.

**If the user wants help refactoring a specific module**: Switch into implementation mode —
produce the refactored code, not just suggestions.

**If the user is unsure what they want**: Start with the Overview and Module Depth Scorecard,
then ask "want me to go deeper on any of these areas?"

---

## Reference Files

- `references/smells.md` — Full catalogue of code smells with examples. Read when doing a
  detailed review of a specific file or when you need examples to cite.
- `references/deep-modules-primer.md` — Summary of Ousterhout's deep module theory with
  examples. Read if the user seems unfamiliar with the concept and needs explanation.

---

## Related Agents

This skill performs an architectural review of an existing codebase (smells, deep
modules, module boundaries). For complementary, finer-grained passes, delegate via
the Agent tool:

- **`code-reviewer`** — when the user wants a diff-level review of staged/unstaged
  changes (TypeScript / Next.js / Bun focus). Prefer the `diff-review` skill if a
  diff exists; use the agent directly only when the diff is already framed.
- **`security-reviewer`** — when the review surfaces auth, input handling, secrets,
  or any OWASP-adjacent concern. Hand off the specific files and let the agent
  produce its own report; do not inline its checks here.
- **`refactor-cleaner`** — once architectural targets are identified and the user
  wants the dead-code / duplicate consolidation pass executed.
- **`database-reviewer`** — for any Postgres/Supabase schema or query findings.

Use a single Agent call per concern. Do not try to do all of the above inline —
this skill stays at the architectural layer; the agents own the detail work.