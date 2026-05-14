# Deep Modules Primer

A brief summary of Ousterhout's deep module theory for use when explaining concepts to users.

---

## The Core Idea

The best modules have two properties in tension:
1. **Simple interfaces** — few things you need to know to use them
2. **Powerful implementations** — they do a lot under the hood

Think of the Unix file I/O API: `open`, `read`, `write`, `close`. Four functions. Those four
functions hide thousands of lines of filesystem, buffering, and OS code. That's a **deep module**.

Contrast with a class that has 25 methods and each one does one tiny thing. The interface is
as complex as the implementation — nothing is being hidden. That's a **shallow module**.

---

## The Iceberg Model

```
         ┌─────────────────┐
Interface │  open/read/write │  ← small, stable, easy to learn
         └────────┬────────┘
                  │
Implementation    ▼
         ┌─────────────────────────────────────────────────┐
         │  buffering, caching, disk I/O, error recovery,  │
         │  file descriptors, OS syscalls, permissions...  │  ← large, complex, hidden
         └─────────────────────────────────────────────────┘
```

Shallow modules are icebergs where the interface is the same size as the implementation.

---

## Why It Matters

**Cognitive load**: Every public method/export/prop is something a user of the module must
learn, remember, and account for. Deep modules minimise this.

**Change isolation**: If the implementation details are hidden, you can change them without
breaking callers. A shallow module forces callers to know (and depend on) implementation details.

**Composition**: Deep modules are easier to combine because their interfaces are small and
well-defined.

---

## Common Misunderstanding: Small ≠ Deep

A module can be short AND shallow. A 10-line pass-through function is still shallow.
A module can be long AND deep. A 500-line parser with a `parse(input: string): AST` interface is deep.

The ratio that matters is **interface complexity vs. implementation complexity**, not lines of code.

---

## What "Interface" Means

Interface isn't just the function signature — it includes:
- All the parameters and their meanings
- What the caller must set up before calling
- What the caller must do after calling
- All the errors/edge cases the caller must handle
- Any assumptions about global state the caller must maintain

A function with 2 parameters but 8 documented "gotchas" has a large interface.

---

## Applying This in Review

Ask for each module:
1. **Can I describe what this does in one sentence?** If not, it may lack cohesion.
2. **How much does a caller need to know to use it safely?** That's the real interface size.
3. **What would break if I changed the implementation?** That's what's leaking through the interface.
4. **Is this hiding complexity, or just moving it around?** Pass-throughs don't create depth.