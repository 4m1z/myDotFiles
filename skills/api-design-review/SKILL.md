---
name: api-design-review
description: >
  Review an API contract before or after it ships: resource shape and naming,
  input validation, authorization, pagination, error format, idempotency,
  rate limits, and versioning. Use when designing a new endpoint, changing an
  existing response or request shape, or when asked to "review this API",
  "check this endpoint", "is this contract correct", "should this be REST",
  "how should we paginate". Not for internal refactors that do not change a
  public contract.
---

# API Design Review

Review the contract first, the implementation second. A contract is a promise
to clients you cannot see.

## Gather the facts first

- the route, method, and the request/response shapes as they exist (or as
  proposed) — read the handler, the schema, and the client that calls it
- who the clients are: first-party app, public API, mobile app with old
  versions in the wild?
- the auth model in this codebase (session, JWT, API key, service token) and
  how the endpoint currently authorizes

Do not review from the diff alone; read the neighbouring endpoints so the
review matches the conventions already in use.

## The checklist

**Shape and naming**
- Resource-oriented paths (`/notes/{id}`), not verbs (`/getNote`).
- Plural nouns, stable ids, no database ids leaking as `id` when the client
  needs a public id.
- Request and response field names consistent with the rest of the API
  (snake_case vs camelCase — one rule, applied).

**Validation**
- Every input validated at the boundary (schema, type, range, format,
  length). Unknown fields: rejected or ignored — decide, don't drift.
- Pagination bounds, page size caps, sort keys allow-listed.
- No business rule enforced only in the client.

**Authorization**
- Authentication present on every non-public route.
- Authorization checked on the object, not just the route: the caller must own
  (or be allowed) the resource. IDOR is the default failure here.
- Tenant/organization scoping applied in the query, not after the fetch.

**Errors**
- One error shape across the API: a stable machine-readable code, a
  human-readable message, and a field pointer for validation errors.
- Correct status codes: 400 malformed, 401 missing/invalid auth, 403
  authenticated but not allowed, 404 missing *or hidden by authorization*,
  409 conflict, 422 semantic failure, 429 rate limited, 5xx server fault.
- Internal details (stack traces, SQL, provider errors) never leak to
  clients.

**Pagination and performance**
- Cursor pagination for large or changing collections; offset only for small,
  stable ones. A cap on page size.
- The response says how to get the next page.

**Idempotency and side effects**
- POSTs that create or charge accept an idempotency key, or are naturally
  idempotent.
- Non-idempotent endpoints document the retry behaviour.

**Versioning and evolution**
- How are breaking changes shipped? Additive changes only, or a version
  prefix? Deprecated fields still have a removal date.
- New optional fields are safe for old clients; required new fields are not.

## Output

Report findings ordered by severity, each with: the contract element, the
concrete failure it causes (for whom), and the smallest fix that removes it.
Separate "must fix before clients use this" from "polish". Recommend the fix
that fits the existing architecture — do not propose a framework rewrite to
solve a missing index.

## Boundaries

- Not a performance review of queries or infrastructure.
- Not a security audit of the whole service (use `production-readiness` or a
  security skill for that).
- Do not redesign an API that already has consumers; propose a versioned
  migration path instead.
