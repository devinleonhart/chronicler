# Chronicler

A full-stack web app for managing fictional universe timelines — characters, groups, and events.

## Tech Stack

- **Frontend**: Nuxt 4 (SPA mode, `ssr: false`), Vue 3, Pinia, Radix Vue, vis-timeline
- **Backend**: H3 (Nuxt server routes), Drizzle ORM
- **Database**: PostgreSQL 17 — `chronicler_dev` (port 5432), `chronicler_test` (port 5433)
- **Package manager**: pnpm
- **Language**: TypeScript throughout

## Commands

```bash
pnpm dev                   # Start dev server
pnpm test                  # Run backend tests (Vitest)
pnpm test:server:coverage  # Run tests with coverage
pnpm lint                  # ESLint check
pnpm quality               # Full suite: test + lint + tsc
pnpm db:migrate            # Run pending Drizzle migrations
pnpm db:seed               # Seed sample "Knighthood" universe
pnpm db:studio             # Open Drizzle Studio GUI
```

## Architecture

### File layout

```
app/             # Nuxt frontend (pages, components, stores, composables)
server/api/      # H3 REST endpoints (file-based routing)
server/db/       # Drizzle schema, migrations, seed, utilities
server/utils/    # Shared server helpers
server/test/     # Vitest integration tests
```

### Data model

- **UniverseSettings** — single-row config (universe name, start/end dates, current day)
- **Character** — name, birthDate, deathDate (nullable); YYYY-MM-DD strings
- **Group** — collection of characters (many-to-many via `characterGroup` junction)
- **Event** — name, startDate, endDate (nullable), `isCurrentDay` flag; many-to-many with characters

### Key architectural decisions

- All dates stored as `varchar(10)` YYYY-MM-DD strings, never JS Date objects or timestamps
- `isCurrentDay` flag on Event marks the "Current Day" reference event (auto-created with settings)
- Nuxt SPA mode: root `/` redirects to `/events`; source dir is `app/`
- Tests use a separate database on port 5433; `NODE_ENV=test` or `VITEST` env var selects it
- Test suite runs serialized (`maxWorkers: 1`); global setup drops/recreates schema before run
- Coverage threshold: 70% (statements, branches, functions, lines)

## Code Conventions

- Server API routes follow Nuxt file-based naming: `[id].get.ts`, `index.post.ts`, etc.
- All server routes validate dates against universe bounds using `validateUniverseDates()`
- Character age calculation lives in `app/lib/ageCalculator.ts` (used on both frontend and summarizer)
- Pinia stores handle all HTTP calls via axios; components do not call the API directly
- Use `parseId()` from `server/utils/parseId.ts` for route parameter IDs
- Use `handleUnknownError()` from `server/utils/handleUnknownError.ts` for error responses

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DATABASE_URL` | `postgres://postgres:postgres@localhost:5432/chronicler_dev` | Dev DB connection |
| `NODE_ENV` | — | Set to `test` to use port 5433 test DB |
| `VITEST` | — | Auto-set by vitest; also triggers test DB selection |
| `API_KEY` | — | When set, all `/api/*` routes require `Authorization: Bearer <key>`; unset = no auth (safe for local dev) |

## See Also

- Database schema: `server/db/schema.ts`
- ORM relations: `server/db/relations.ts`
- Test helpers: `server/test/helpers.ts`
