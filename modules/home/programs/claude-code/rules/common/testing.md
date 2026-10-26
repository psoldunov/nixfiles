# Testing Requirements

## Minimum Test Coverage: 80%

Test Types (ALL required):
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)

## Test-Driven Development

Build features and fix bugs test-first: call the Skill tool with `tdd`. It owns
the red → green loop, where tests go (seams agreed with the user up front) and
what makes a test worth keeping. Check coverage once the loop is done.

## Troubleshooting Test Failures

1. Cause unclear: call the Skill tool with `diagnosing-bugs`
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)
