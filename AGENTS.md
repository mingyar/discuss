# Discuss — AGENTS.md

## Critical workflow

- **`mix precommit`** runs: `compile --warnings-as-errors` → `deps.unlock --unused` → `format` → `test`. Use this before every commit.
- **Never commit or push without asking.** Always ask "can I commit and push?" and wait for confirmation.
- **Format HEEx carefully.** The `.formatter.exs` includes `Phoenix.LiveView.HTMLFormatter`. Long `<.link navigate={...}>` attributes must be split across multiple lines or CI (`mix format --check-formatted`) fails.

## Setup & environment

- PostgreSQL required locally. No Docker DB for dev.
- **GitHub OAuth** for authentication. Set these env vars or `source .env`:
  - `GITHUB_CLIENT_ID`
  - `GITHUB_CLIENT_SECRET`
- `mix setup` installs deps, creates DB, migrates, builds assets.
- `mix phx.server` starts dev server on port 4000.

## Architecture

- **Contexts:** `Discuss.Accounts` (users) and `Discuss.Discussions` (topics & comments).
- **LiveViews:** `DiscussWeb.TopicLive.Index` (topic list + inline composer) and `DiscussWeb.TopicLive.Show` (topic detail + comments).
- **PubSub channels:** `"topics"` for topic CRUD broadcasts; `"topic:#{topic_id}"` for comment broadcasts.
- **All routes are public** — no auth guards applied at router level (known gap).
- **PLAN.md** has a full audit with prioritized gaps. Reference it before making architectural decisions.

## LiveView patterns (repo-specific)

- **Streams for all collections.** Topics and comments use `phx-update="stream"`. **Do not use regular assigns for lists.**
- **Assign changes don't update streamed items.** If you toggle an assign like `@editing_topic_id` that affects content inside a streamed item, you **must** also call `stream_insert` for that item.
- **`phx-value-*` sends strings** — always. To send proper JSON types (e.g. integer IDs), use `JS.push("event", value: %{id: topic.id})` instead.
- **Colocated hooks** use `<script :type={Phoenix.LiveView.ColocatedHook}>` with names starting with `.` (e.g. `.TitleEditFocus`). Elements with `phx-hook` **must** have an `id` attribute.
- **External hooks** (e.g. `ScrollToBottom`) live in `assets/js/hooks.js` and must be registered in the `LiveSocket` constructor.

## Testing

- `use DiscussWeb.ConnCase, async: true` for LiveView/integration tests.
- **Auth in tests:** `conn = init_test_session(conn, user_id: user.id)` to set the logged-in user.
- **Fixtures:** `user_fixture/0` (from `AccountsFixtures`), `topic_fixture/1`, `comment_fixture/2` (from `DiscussionsFixtures`).
- **Real-time tests:** Simulate broadcasts via `send(lv.pid, {:topic_created, topic})` (preloaded with associations).
- **PubSub subscriptions** must be guarded by `if connected?(socket)` in `mount/3` to avoid double subs.

## Deployment (Fly.io)

- **Build release on the runner, not in Docker.** The OTP httpc TLS client breaks inside Docker during `mix deps.get`. Package the pre-built release instead.
- **Clean stale release before `mix release`:** `rm -rf _build/prod/rel/discuss/` — cached release files from previous CI runs can reintroduce stale config.
- CI pushes to `master` only. Requires `FLY_API_TOKEN` secret.

## Asset pipeline

- **Tailwind v4** — no `tailwind.config.js`. Uses `@import "tailwindcss" source(none); @source ...` in `assets/css/app.css`.
- **Custom warm palette** overrides daisyUI `--color-base-*` tokens (hue shifted to 85). Never hardcode colors in templates.
- **Only `app.js` and `app.css` bundles** — no external vendor `<script>` or `<link>` tags in layouts.

## HTTP client

- Use the included `Req` library for HTTP requests. **Never** add `:httpoison`, `:tesla`, or `:httpc` as dependencies.
