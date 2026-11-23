---
paths:
  - "db/**"
  - "app/models/**"
  - "app/controllers/api/**"
---

# Data Rules

## Dates
- YYYY-MM-DD strings, compared as strings. Arithmetic goes through `CalendarDate`, in the Gregorian calendar.
- `calendar_date: true` refuses impossible dates; `universe_bounds: true` checks changed dates against the universe.
- A death before birth and an end before its start are refused.

## Memberships
- Assigning `group_ids` or `character_ids` is staged by `StagedMembers`: checked, then written on save, in its transaction.
- Join tables have composite primary keys. Deleting a character removes its memberships; deleting a group keeps its characters.
- An event's members must be alive at some point during it. This is rechecked only when its dates or members change.

## Special records
- `UniverseSetting.current!` creates the settings and the Current Day event if missing.
- The Current Day event cannot be deleted, and moves with `current_day`.

## Migrations
- The first migration converts the Nuxt schema in place. `db:migrate VERSION=0` restores it.
- `lib/tasks/legacy_database.rake` keeps `db:migrate` from loading `db/schema.rb` into an unconverted database.

## API
- Controllers read the raw JSON body through `body`; Rails does not parse it, so types are not coerced.
- Check a change with `contract/replay.rb verify` against a database freshly loaded from `contract/seed.sql`.
