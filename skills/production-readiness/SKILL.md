---
name: production-readiness
description: >
  Review a service or release before it goes live: error handling and failure
  modes, observability (logs, metrics, traces), deployment and rollback risk,
  environment configuration and secrets, security exposure, test coverage of
  the critical paths, and performance under expected load. Use when asked to
  "is this ready to ship", "pre-launch review", "production checklist",
  "what could break in prod", "audit this service", "release review", or
  before a launch, migration, or pricing change. Not for feature work in
  progress and not a substitute for a full security audit.
---

# Production Readiness

A release review over the whole path a request takes. Work from evidence in
the repo and the running system, not from assumptions.

## 1. Scope the change

What exactly is going out? A diff, a release branch, a migration, a config
change. Identify:

- the user-facing behaviour that changes
- the data changes (schema, backfill, deletion)
- the new dependencies (packages, services, env vars, third-party APIs)
- the rollback path: can this be reverted without data loss?

## 2. Failure modes

For each new or changed path ask: what happens when the dependency is slow,
down, or returns garbage?

- Timeouts and retries: are they bounded, with backoff? A retry without a cap
  is an outage amplifier.
- Partial failure: if step 3 of 5 fails, is the state consistent? Use
  transactions or idempotent operations.
- Degraded mode: does the feature fail closed (safe) or fail open (leaks,
  costs money, corrupts data)?
- Resource exhaustion: unbounded input, unbounded queries, unbounded memory,
  unbounded queue growth. Check every user-controlled value that reaches a
  limit.

## 3. Observability

- Does the new code emit logs that identify the request (correlation id) and
  the failure, at a level that is actually useful? No secrets, no PII, no
  full payloads of sensitive data.
- Are there metrics for the things you would want to alert on: error rate,
  latency (p50/p95), saturation, and the business signal of the feature?
- Would you notice this breaking in production within minutes? If not, add the
  check before shipping.
- Are alerts actionable and owned, with a runbook link?

## 4. Configuration and secrets

- Every new setting has a default that is safe when unset, and fails loudly
  when misconfigured (a startup check beats a runtime null).
- Secrets come from the environment or the secret store, never from the repo
  or a committed `.env`. No new secret is printed to a log.
- The new config is present in every environment it needs (dev, staging,
  prod) and absent where it should not be. Feature flags default to off.

## 5. Security exposure

- New endpoints: authenticated, authorized, rate-limited, size-limited.
- New input: validated, escaped, parameterized; no string-built SQL; no
  untrusted deserialization; no path traversal; no SSRF via user-supplied
  URLs.
- New dependencies: pinned versions, lockfile updated, no known critical
  advisories. Check the diff's dependency changes explicitly.
- Secrets and PII do not reach logs, analytics events, or error reports.

For a focused review, use `differential-review` (or the security skills from
the Trail of Bits collection) on the diff; this skill is the whole-service
pass.

## 6. Tests

- The critical path of the change is covered by an automated test that would
  fail if the change were reverted.
- Migrations: forward tested on a copy of production-shaped data; a rollback
  or a documented "irreversible, here's the plan".
- The test suite passes on the exact commit being released (show the output).

## 7. Performance

- The hot path's cost: the queries added, their indexes, the N+1s introduced,
  the payload sizes, the cache behaviour. Measure the change, do not guess.
- Anything that scales with users or data is bounded, paginated, or cached.

## Output

A verdict — **ready**, **ready with follow-ups**, or **not ready** — followed
by findings ordered by severity, each with: the concrete failure it causes,
the evidence, and the smallest fix. Then the release steps: what to watch
after deploy, and the rollback command.

## Boundaries

- Not a code-style review.
- Not a load test; if load is the question, say what to measure and how.
- Do not add infrastructure, queues, or platforms the change does not need.
