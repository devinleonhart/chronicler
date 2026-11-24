# Chronicler

A web app for managing fictional universe timelines: characters, groups and events.

## Tech Stack

- **Application**: Rails 8.1 on Ruby 4.0, with Hotwire (Turbo, Stimulus), importmap, propshaft and Tailwind
- **Database**: PostgreSQL 18 (Debian image; name order depends on its locale)
- **Specs**: RSpec, with Cuprite and Chromium for system specs
- **MCP server**: plain Ruby over stdio, in `mcp/`

## Commands

All Ruby runs in containers.

```bash
docker compose up web                                    # http://localhost:3000
docker compose run --rm -e RAILS_ENV=test web bin/ci     # everything CI checks; ends in OK
docker compose run --rm -e RAILS_ENV=test web rspec spec/models
docker compose run --rm web bin/rails db:migrate
docker compose run --rm web bin/rails db:seed:replant    # empties development, loads the sample universe
docker compose run --rm web bin/rails users:create       # the one user; users:password changes the password
docker compose run --rm web bin/rails mcp:tokens:issue MACHINE=name   # prints a token once; also :list, :revoke
docker compose build web                                 # after changing a Gemfile
```

## Architecture

```
app/controllers/        # Pages: ERB, Turbo, session sign-in
app/controllers/api/    # JSON API for the MCP server and scripts: bearer key
app/models/             # The rules, shared by both
app/operations/         # What the API and the MCP tools do, without HTTP
app/mcp/                # MCP tools, served at /mcp
app/services/           # Ages, summary text, event list, current-day roster
mcp/                    # The stdio MCP server, to be removed
contract/               # Recorded behavior of the API, and a script to replay it
db/legacy_schema.sql    # The schema before Rails, which the first migration converts
```

### Data model

- **UniverseSetting**: single row with the name, start and end dates, and current day
- **Character**: name, birth date, optional death date
- **Group**: characters, through `character_groups`
- **Event**: name, start date, optional end date, `is_current_day`; characters, through `event_characters`
- **User**, **Session**: one user, created by a command

### Key decisions

- Dates are `varchar(10)` YYYY-MM-DD strings, never Ruby dates or timestamps. `CalendarDate` checks them.
- Pages and API are separate controllers over the same models; neither calls the other.
- Rules belong in the models, as typed errors. `Api::ErrorMessage` gives them the API's wording.
- The API's paths, JSON, status codes and messages are fixed by `contract/`.
- `/mcp` exists only when `MCP_HOST` is set, answers only that host, and takes tokens, not the API key.
- Migrations never run at boot.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Production database |
| `API_KEY` | Bearer key for `/api`; production does not boot without it, development runs unchecked |
| `SECRET_KEY_BASE` | Production secret |
| `MCP_HOST` | The only host that `/mcp` answers; unset, `/mcp` does not exist |
| `APP_HOST` | The host production answers to (default `chronicler.devleo.me`) |
| `DEVELOPMENT_DATABASE_URL`, `TEST_DATABASE_URL` | Set by compose; not `DATABASE_URL`, which would apply to both |
| `CHRONICLER_URL`, `CHRONICLER_API_KEY` | Read by the MCP server |
