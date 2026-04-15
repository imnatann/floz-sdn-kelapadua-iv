# FLOZ Mobile API Contract v1

**Base URL:** `https://<host>/api/v1`
**Status:** Stable as of 2026-04-15
**Source of truth:** This file. Any deviation in code is a bug.

## Envelope

### Single resource success
```json
{ "data": { ... } }
```

### Collection success
```json
{
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 145,
    "last_page": 8
  }
}
```

### Error
```json
{
  "message": "Pesan singkat untuk user.",
  "errors": {
    "field_name": ["Pesan validasi 1", "Pesan validasi 2"]
  },
  "code": "VALIDATION_ERROR"
}
```

`errors` and `code` are optional; `message` is always present on error.

## HTTP Status Mapping

| Code | Meaning |
|---|---|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request (malformed body) |
| 401 | Unauthenticated (token invalid/missing) |
| 403 | Forbidden (authz fail) |
| 404 | Not Found |
| 422 | Validation Error |
| 429 | Rate Limit |
| 500 | Server Error (generic message; full trace in logs only) |

## Field Conventions

- `id` is always integer
- All datetimes are ISO 8601 UTC (e.g. `2026-04-15T08:00:00Z`); mobile converts to Asia/Jakarta for display
- All keys are snake_case
- File / image / pdf URLs are absolute (`https://...`)
- Booleans are real booleans, never `0`/`1` strings

## Pagination

- Query: `?page=1&per_page=20`
- Defaults: `per_page=20`, max `100`
- Out-of-range page → returns empty `data` with valid `meta`
- Response includes `meta` block as shown above

## Filtering

- Via query string: `?class_id=4&date=2026-04-15`
- Each endpoint documents its own allowed filters

## Headers

### Request
- `Authorization: Bearer <sanctum-token>` (except `/auth/login`)
- `Accept: application/json`
- `X-Client: floz-mobile/1.0.0`

### Response
- `Content-Type: application/json`
- `X-Api-Version: v1`

## Rate Limiting

- Login endpoint: `5 per minute per IP`
- Authenticated endpoints: `60 per minute per user`
- Exceeded → `429 Too Many Requests` with envelope error

## Versioning

Path-based: `/api/v1/...`. Breaking changes ship as `/api/v2/...` in parallel; v1 is never mutated post-stable.

## Auth

- Bearer token via Sanctum Personal Access Token
- Token name: `mobile`
- Single-device policy: a successful login revokes any existing `mobile`-named tokens for that user
- Logout revokes the current token only

## Role Restrictions

- `student`, `teacher`, `school_admin` → may log in
- `parent` → 403 with message "Akun parent belum didukung di mobile saat ini"
- `super_admin` → out of scope (no mobile shell)
