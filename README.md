# Discuss

A real-time discussion board built with Phoenix LiveView. Authenticated users can create topics (threads) and post comments — everything updates live across all connected users via PubSub.

## Features

- **GitHub OAuth** — Sign in with your GitHub account
- **Topics** — Create, edit, and delete discussion threads
- **Comments** — Post and delete comments on topics (live updates)
- **Real-time** — New topics and comments appear instantly via WebSockets
- **Dark mode** — System/Light/Dark theme toggle with localStorage persistence
- **Responsive** — Mobile-friendly layout
- **Health checks** — Liveness and readiness endpoints for zero-downtime deploys

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Phoenix 1.8.3 |
| LiveView | 1.1.23 |
| HTTP Server | Bandit |
| Database | PostgreSQL |
| Assets | Tailwind CSS 4, esbuild |
| Auth | Ueberauth + GitHub OAuth |
| Hosting | Fly.io |
| CI/CD | GitHub Actions |

## Local Setup

### Prerequisites

- Elixir ~> 1.15, OTP 26+
- PostgreSQL running locally
- A [GitHub OAuth App](https://github.com/settings/developers) (for dev)

### Quick Start

```bash
# 1. Set GitHub OAuth credentials
export GITHUB_CLIENT_ID=your_dev_client_id
export GITHUB_CLIENT_SECRET=your_dev_client_secret

# 2. Install deps and create database
mix setup

# 3. Start the server
mix phx.server

# 4. Open http://localhost:4000
```

> A `.env` file with dev credentials is included. Run `source .env` to load it.

### GitHub OAuth (Dev)

Create an OAuth App at GitHub → Settings → Developer Settings with:

- **Homepage URL:** `http://localhost:4000`
- **Callback URL:** `http://localhost:4000/auth/github/callback`

### Useful Commands

| Command | Description |
|---------|-------------|
| `mix setup` | Full project setup (deps, DB, assets) |
| `mix test` | Run tests |
| `mix phx.server` | Start dev server |
| `mix precommit` | Compile, format, test — all checks |
| `iex -S mix phx.server` | Start server with IEx shell |

## Deployment

### Production on Fly.io

```bash
# Set secrets
flyctl secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
flyctl secrets set DATABASE_URL="postgresql://..."
flyctl secrets set GITHUB_CLIENT_ID="..."
flyctl secrets set GITHUB_CLIENT_SECRET="..."

# Deploy
flyctl deploy
```

### CI/CD

Every push to `main` triggers GitHub Actions:

1. **Test** — Compile, format check, run test suite
2. **Deploy** — Build Docker image, run migrations (rolling deploy)

Requires `FLY_API_TOKEN` secret in GitHub repository settings.

## Architecture

```
Discuss
├── Accounts        — User management, GitHub OAuth
├── Discussions     — Topics and comments, PubSub broadcasts
├── DiscussWeb
│   ├── TopicLive   — LiveView: Index (topic list + composer), Show (topic + comments)
│   ├── Auth        — AuthController, SetUser/RequireAuth plugs
│   ├── Health      — Liveness and readiness endpoints
│   └── Components  — Layouts, FormComponent, UI components
└── Release         — DB migration helper for Fly.io release command
```

## API Routes

| Path | Description |
|------|-------------|
| `/` | Home |
| `/topics` | Topic listing |
| `/topics/:id` | Topic detail + comments |
| `/health/*` | Health checks |
| `/auth/github` | GitHub sign in |
| `/auth/github/callback` | OAuth callback |
| `/dev/dashboard` | LiveDashboard (dev only) |

## License

MIT
