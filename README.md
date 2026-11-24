# Chronicler

Keeps the timeline of a fictional universe: its characters, groups and events.

## Features

| Address | Gives |
|---|---|
| `/events` | The events, in order, with the characters in each |
| `/current-day` | Who is alive on the current day, and at what age |
| `/characters`, `/groups` | The characters and the groups they belong to |
| `/summary` | The universe as text |
| `/settings` | The universe's name, its first and last day, and the current day |
| `/api` | The same data as JSON, for scripts with the API key |
| `/mcp` | MCP, for hosts and tokens that are allowed |

One user signs in to the pages. Dates are `YYYY-MM-DD` text, never Ruby dates, whose calendar changes in 1582.

## Development

Needs Docker; all Ruby runs in containers.

```bash
docker compose up web                                    # http://localhost:3000
docker compose run --rm web bin/rails db:seed:replant    # empties development, loads the sample universe
docker compose run --rm web bin/rails users:create       # the one user; users:password changes the password
docker compose run --rm -e RAILS_ENV=test web bin/ci     # everything CI checks; ends in OK
docker compose build web                                 # after changing a Gemfile
```

## Environment

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Production database |
| `SECRET_KEY_BASE` | Production secret |
| `API_KEY` | Bearer key for `/api`; production does not boot without it, development runs unchecked |
| `APP_HOST` | The host production answers to (default `chronicler.devleo.me`) |
| `MCP_HOST` | The only host that `/mcp` answers; unset, `/mcp` does not exist |

## MCP

`POST /mcp` offers the settings, characters, groups, events and summary as tools. It takes tokens, not the API key.

Each machine has its own token, which carries `read`, `write` or `delete` and expires:

```bash
bin/rails mcp:tokens:issue MACHINE=<name> SCOPES=read,write DAYS=90   # prints the token once
bin/rails mcp:tokens:list
bin/rails mcp:tokens:revoke ID=<id>
```

The endpoint, limits and tokens come from the [`tailnet_mcp`](https://github.com/devinleonhart/tailnet-mcp) gem. The tools are in `app/mcp`.

## Deployment

A merge to `master` runs CI, which publishes `devleo/chronicler:latest` to Docker Hub when the checks pass. On the server:

```bash
docker compose pull chronicler
docker compose run --rm --no-deps chronicler bin/rails db:migrate   # only with a new migration
docker compose up -d chronicler
```

Migrations never run at boot.

## Architecture

```
app/controllers/        # Pages: ERB, Turbo, session sign-in
app/controllers/api/    # JSON API for scripts: bearer key
app/models/             # The rules, shared by both
app/operations/         # What the API and the MCP tools do, without HTTP
app/mcp/                # MCP tools
app/services/           # Ages, summary text, event list, current-day roster
contract/               # Recorded behavior of the API, and a script to replay it
```

Pages and API are separate controllers over the same models; neither calls the other. The API's paths, JSON, status codes and messages are fixed by `contract/`.
