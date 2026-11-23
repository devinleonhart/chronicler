---
paths:
  - "server/db/**"
  - "server/api/**"
  - "server/utils/**"
---

# Database Rules

## Dates
- All dates are `varchar(10)` YYYY-MM-DD strings — never use JS Date, timestamps, or ISO 8601
- Always validate dates against universe bounds using `validateUniverseDates()` before insert/update
- Character lifespans (birthDate < deathDate) validated via `validateCharacterLifespans()`

## ORM
- Use Drizzle ORM for all queries — schema in `server/db/schema.ts`, relations in `server/db/relations.ts`
- Get the db instance from `server/utils/db.ts` (connection pool, environment-aware)
- After schema changes: run `pnpm db:generate` to create migration SQL, then `pnpm db:migrate`

## Junction tables
- `characterGroup`: links Character ↔ Group (cascade delete on both FKs)
- `eventCharacter`: links Event ↔ Character (cascade delete on both FKs)
- Deleting a character auto-removes its group/event memberships; deleting a group does NOT delete characters

## Special records
- `UniverseSettings` is a singleton (one row); `settings/index.get.ts` auto-initializes it if absent
- The "Current Day" Event (`isCurrentDay = true`) is auto-created alongside settings — never delete it directly

## Testing
- Test DB: `chronicler_test` on port 5433; selected when `NODE_ENV=test` or `VITEST` is set
- Global setup drops/recreates the schema; per-test setup clears all rows and resets sequences
- Use helpers from `server/test/helpers.ts` to create fixtures (`createTestCharacter`, etc.)
