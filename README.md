<div align="center">

# Discuss

**Real-time discussion board built with Phoenix LiveView**

[![CI](https://github.com/mingyar/discuss/actions/workflows/deploy.yml/badge.svg)](https://github.com/mingyar/discuss/actions/workflows/deploy.yml)
[![Elixir](https://img.shields.io/badge/Elixir-1.18-4B275F?logo=elixir&logoColor=white)](https://elixir-lang.org)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.8-FD4F00?logo=phoenix&logoColor=white)](https://phoenixframework.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

Sign in with GitHub, create topics, post comments — everything updates live across all connected users via WebSockets. No page refreshes needed.

---

## ✨ Features

- **🔐 GitHub OAuth** — One-click sign in with your GitHub account
- **💬 Topics & Comments** — Create, edit, and delete discussion threads
- **⚡ Real-time** — New topics and comments appear instantly via PubSub
- **🌙 Dark mode** — System / Light / Dark toggle, persisted across sessions
- **📱 Responsive** — Works great on desktop and mobile
- **❤️ Health checks** — Liveness + readiness endpoints for zero-downtime deploys

## 🛠 Tech Stack

| Layer | Choice |
|-------|--------|
| **Framework** | Phoenix 1.8 + LiveView 1.1 |
| **Database** | PostgreSQL |
| **Styling** | Tailwind CSS 4 + daisyUI |
| **Auth** | Ueberauth + GitHub OAuth |
| **Hosting** | Fly.io |
| **CI/CD** | GitHub Actions |

## 🚀 Quick Start

### Prerequisites

- Elixir ~> 1.18, OTP 27+
- PostgreSQL running locally
- A [GitHub OAuth App](https://github.com/settings/developers) (for local dev)

### Setup

```bash
# 1. Set your GitHub OAuth credentials
export GITHUB_CLIENT_ID=your_dev_client_id
export GITHUB_CLIENT_SECRET=your_dev_client_secret

# 2. Install dependencies, create database, build assets
mix setup

# 3. Start the server
mix phx.server

# 4. Open http://localhost:4000 🎉
```

> A `.env` file with dev credentials is included — run `source .env` to load it.

### GitHub OAuth (Dev)

Create an OAuth App at [GitHub Developer Settings](https://github.com/settings/developers) with:

| Field | Value |
|-------|-------|
| **Homepage URL** | `http://localhost:4000` |
| **Callback URL** | `http://localhost:4000/auth/github/callback` |

### Useful Commands

| Command | What it does |
|---------|--------------|
| `mix setup` | Full project setup (deps, DB, assets) |
| `mix test` | Run the test suite |
| `mix phx.server` | Start the dev server |
| `mix precommit` | Format → Compile → Test (all checks) |
| `iex -S mix phx.server` | Dev server with an IEx shell |

## 📦 Deployment

### Fly.io

```bash
# Set production secrets
flyctl secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
flyctl secrets set DATABASE_URL="postgresql://..."
flyctl secrets set GITHUB_CLIENT_ID="..."
flyctl secrets set GITHUB_CLIENT_SECRET="..."

# Deploy
flyctl deploy
```

### CI/CD

Every push to `master` triggers GitHub Actions:

1. **Test** — Compile, format check, test suite
2. **Deploy** — Build Docker image, run migrations, rolling deploy

> Requires `FLY_API_TOKEN` secret in the repository settings.

## 🧱 Architecture

```
discuss/
├── discuss/
│   ├── accounts/        # User management, GitHub OAuth
│   └── discussions/     # Topics, comments, PubSub broadcasts
├── discuss_web/
│   ├── live/
│   │   ├── topic_live/  # Index (list + composer), Show (detail + comments)
│   │   └── ...          # Other LiveViews
│   ├── controllers/     # AuthController, HealthController
│   └── components/      # Layouts, shared UI components
└── releases/            # Migration helper for Fly.io release command
```

## 🗺 Routes

| Path | What it does |
|------|--------------|
| `/` | Home |
| `/topics` | Topic listing |
| `/topics/:id` | Topic detail + comments |
| `/health/liveness` | Liveness probe |
| `/health/readiness` | Readiness probe |
| `/auth/github` | Sign in with GitHub |
| `/auth/github/callback` | OAuth callback |
| `/dev/dashboard` | LiveDashboard (dev only) |

## 📄 License

This project is licensed under the MIT License.
