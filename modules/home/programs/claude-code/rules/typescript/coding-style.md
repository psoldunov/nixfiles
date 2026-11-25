---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with TypeScript/JavaScript specific content.

## Immutability

Use spread operator for immutable updates.

Wrong, it mutates the caller's object:

```typescript
function updateUser(user, name) {
  user.name = name
  return user
}
```

Right, it returns a new object:

```typescript
/**
 * Renames a user without touching the original.
 *
 * @param user - The user to rename.
 * @param name - The new name.
 * @returns A copy of `user` with `name` replaced.
 */
function updateUser(user: User, name: string): User {
  return {
    ...user,
    name
  }
}
```

## Error Handling

Use async/await with try-catch:

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('Detailed user-friendly message')
}
```

## Input Validation

Use Zod for schema-based validation:

```typescript
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

const validated = schema.parse(input)
```

## Console.log

- No `console.log` statements in production code
- Use proper logging libraries instead
- See hooks for automatic detection
