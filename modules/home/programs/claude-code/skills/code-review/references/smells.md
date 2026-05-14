# Code Smells Catalogue

A reference for the code-review skill. Grouped by category with examples.

---

## Module Depth Smells

### Pass-through module
A module whose only job is to call another module with no added logic.

```ts
// ❌ Shallow — why does this exist?
export function getUser(id: string) {
  return userRepository.findById(id);
}

// ✅ Deep — adds something (caching, validation, transformation)
export async function getUser(id: string): Promise<User> {
  const cached = await cache.get(`user:${id}`);
  if (cached) return cached;
  const user = await userRepository.findById(id);
  if (!user) throw new NotFoundError(`User ${id}`);
  await cache.set(`user:${id}`, user, { ttl: 300 });
  return user;
}
```

### Re-export barrel with no value
Barrel files (index.ts) that only re-export are fine for ergonomics, but a module that
*only* exists to re-export without adding any cohesion is a smell.

```ts
// ❌ This file does nothing — just delete the indirection
// lib/user/index.ts
export { getUser } from './getUser';
export { deleteUser } from './deleteUser';
export { updateUser } from './updateUser';
// (each of these files is also 3 lines long)
```

### Getter/setter proliferation
When every private field gets a getter, the abstraction is not hiding anything.

```ts
// ❌ This class has no encapsulation value — use a plain object
class UserConfig {
  private _name: string;
  private _email: string;
  getName() { return this._name; }
  setName(v: string) { this._name = v; }
  getEmail() { return this._email; }
  setEmail(v: string) { this._email = v; }
}
```

---

## Cohesion Smells

### Boolean flag behaviour switch
A function that takes a boolean to switch between two fundamentally different behaviours
should be two functions.

```ts
// ❌ Does two unrelated things
function fetchUsers(includeDeleted: boolean) { ... }

// ✅ Two clear, composable functions
function fetchActiveUsers() { ... }
function fetchAllUsers() { ... } // or fetchDeletedUsers()
```

### God utility file
A `utils.ts` or `helpers.ts` that has grown to hold 15+ unrelated functions.
Split into purpose-specific modules.

### Mixed abstraction levels
A function that does both high-level orchestration and low-level implementation in the same body.

```ts
// ❌ Mixed levels — orchestration + SQL in same function
async function processCheckout(cart: Cart) {
  const total = cart.items.reduce((sum, i) => sum + i.price, 0);
  const rows = await db.query(`INSERT INTO orders ...`); // low-level detail
  await sendEmail(user.email, 'Your order...'); // side effect
  return rows[0].id;
}

// ✅ Orchestrator calls deep modules
async function processCheckout(cart: Cart) {
  const total = calculateTotal(cart);
  const order = await orderRepository.create({ cart, total });
  await notifications.sendOrderConfirmation(order);
  return order.id;
}
```

---

## Interface Smells

### Too many positional parameters

```ts
// ❌ Hard to read at call site, easy to get order wrong
function createUser(name: string, email: string, role: string, active: boolean, orgId: string) {}

// ✅ Options object — self-documenting, order-independent, extensible
function createUser(options: {
  name: string;
  email: string;
  role: string;
  active?: boolean;
  orgId: string;
}) {}
```

### Temporal coupling (call order dependency)
Callers must call methods in a specific sequence, or the module breaks.

```ts
// ❌ You must call init() before use() — nothing enforces this
const service = new DataService();
// ... somewhere else ...
await service.init(); // easy to forget
await service.use();

// ✅ Factory or constructor handles initialisation
const service = await DataService.create(); // already ready to use
```

### Inconsistent return types

```ts
// ❌ Returns different things — callers must check
function findUser(id: string): User | null | undefined | Error { ... }

// ✅ One return type — throws on error, null if not found
function findUser(id: string): User | null { ... }
```

---

## Coupling Smells

### Business logic in route/controller layer

```ts
// ❌ Route handler doing too much
router.post('/checkout', async (req, res) => {
  const cart = await db.query('SELECT * FROM carts WHERE id = $1', [req.body.cartId]);
  const total = cart.rows[0].items.reduce(...);
  const taxRate = req.user.country === 'US' ? 0.08 : 0.2;
  // ... 50 more lines
});

// ✅ Route handler is thin
router.post('/checkout', async (req, res) => {
  const result = await checkoutService.process(req.user, req.body.cartId);
  res.json(result);
});
```

### Circular dependencies
Module A imports from B, B imports from A. Symptom of modules that are too tightly coupled
and should be merged, or need a third module to hold the shared type/logic.

### Cross-layer imports
A model/entity file importing from a service, a service importing from a route, etc.
Architecture should flow one way: routes → services → repositories → models.

---

## Test Smells (signals about production code quality)

### Tests that break when you rename a private method
Tests are coupled to implementation, not behaviour. The module's internals are too exposed.

### Tests that need to set up 10 other things before testing one thing
The module under test has too many dependencies. It's doing too much.

### No tests for a complex module
Complex modules with no tests often indicate the module is hard to test because it's too
coupled or has too many side effects baked in.