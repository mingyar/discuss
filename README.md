# 💬 Discuss

[![Elixir CI](https://github.com/mingyar/discuss-elixir-bootcamp/actions/workflows/elixir.yml/badge.svg?branch=master)](https://github.com/mingyar/discuss-elixir-bootcamp/actions/workflows/elixir.yml)
[![Phoenix 1.7](https://img.shields.io/badge/Phoenix-1.7.21-blueviolet)](https://www.phoenixframework.org/)
[![Elixir 1.17](https://img.shields.io/badge/Elixir-1.17.2-red)](https://elixir-lang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4.0-38B2AC)](https://tailwindcss.com/)

> A modern discussion forum application built with Phoenix Framework, featuring real-time discussions, user authentication via GitHub OAuth, and a beautiful responsive UI with Tailwind CSS.

## 🎯 Project Overview

**Discuss** is a full-featured discussion forum application that allows users to:
- Create and manage discussion topics
- Post comments on topics with real-time updates
- Authenticate securely via GitHub OAuth
- Participate in live discussions with WebSocket support
- Browse topics and contribute to conversations

Built with a modern tech stack while maintaining the traditional Phoenix architecture (Controllers → Views → Templates), Discuss combines the reliability of proven patterns with cutting-edge tooling.

---

## ✨ Features

### Core Functionality
- 🔐 **GitHub OAuth Authentication** - Secure login with GitHub accounts
- 💬 **Real-time Discussions** - WebSocket-powered live comment updates
- 📝 **Topic Management** - Create, read, and manage discussion topics
- 👥 **User System** - User profiles and comment attribution
- 🎨 **Responsive UI** - Mobile-friendly design with Tailwind CSS

### Technology Highlights
- ⚡ **Phoenix 1.7.21** - Latest stable Phoenix framework
- 🎯 **esbuild** - Lightning-fast JavaScript bundler
- 🎨 **Tailwind CSS** - Utility-first CSS framework for modern styling
- 🗄️ **PostgreSQL** - Reliable relational database
- 🔄 **WebSockets** - Real-time bidirectional communication
- 📦 **Clean Architecture** - DRY, maintainable code

---

## 🚀 Quick Start

### Prerequisites
- **Elixir** 1.17+ ([Install](https://elixir-lang.org/install.html))
- **Erlang** (installed with Elixir)
- **Node.js** 14+ ([Install](https://nodejs.org/))
- **PostgreSQL** 12+ ([Install](https://www.postgresql.org/download/))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mingyar/discuss.git
   cd discuss
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   npm install
   ```

3. **Configure the database**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

4. **Set up GitHub OAuth** (optional, for authentication)
   - Create a GitHub OAuth application in your GitHub settings
   - Add credentials to your local environment:
     ```bash
     export GITHUB_CLIENT_ID="your_client_id"
     export GITHUB_CLIENT_SECRET="your_client_secret"
     ```
   - See [GITHUB_AUTH_FIX.md](./GITHUB_AUTH_FIX.md) for detailed configuration

5. **Start the development server**
   ```bash
   mix phx.server
   ```

6. **Visit the application**
   - Open your browser and navigate to [`http://localhost:4000`](http://localhost:4000)

---

## 📖 Documentation

Comprehensive documentation is included in the project:

| Document | Purpose |
|----------|---------|
| [**UPGRADE_SUMMARY.md**](./UPGRADE_SUMMARY.md) | Quick overview of Phoenix 1.6→1.7 upgrade (5 min read) |
| [**PHOENIX_UPGRADE.md**](./PHOENIX_UPGRADE.md) | Detailed upgrade guide with technical decisions |
| [**DRY_IMPROVEMENTS.md**](./DRY_IMPROVEMENTS.md) | Code refactoring and maintainability improvements |
| [**GITHUB_AUTH_FIX.md**](./GITHUB_AUTH_FIX.md) | OAuth authentication configuration & troubleshooting |
| [**CHANGES.md**](./CHANGES.md) | Complete changelog of all modifications |

---

## 🔄 Recent Upgrade (v0.0.1)

This project has been **recently upgraded** to the latest Phoenix framework with modern tooling:

### What's New ✅
- **Phoenix 1.6.16 → 1.7.21** - Latest stable version
- **esbuild** - Replaced Brunch for 10-100x faster asset compilation
- **Tailwind CSS** - Added modern utility-first CSS framework
- **Phoenix HTML 4.0** - Updated for compatibility
- **DRY Code Refactoring** - Removed 80+ lines of boilerplate code using Elixir macros

### Key Improvements
- ⚡ **50-100x faster** asset compilation (esbuild vs Brunch)
- 📦 **65% code reduction** in view modules through macro metaprogramming
- 🎨 **Modern styling** with Tailwind CSS
- 🔧 **Cleaner configuration** with import Config syntax
- 🎯 **Production-ready** setup

**See [UPGRADE_SUMMARY.md](./UPGRADE_SUMMARY.md) for complete details.**

---

## 🛠️ Development

### Available Commands

```bash
# Start development server with hot-reloading
mix phx.server

# Run tests
mix test

# Format code
mix format

# Run the code linter
mix credo

# Database management
mix ecto.create         # Create database
mix ecto.migrate        # Run pending migrations
mix ecto.rollback       # Rollback last migration
```

### Building for Production

```bash
# Compile assets for production
mix assets.deploy

# Build release
MIX_ENV=prod mix release
```

### Project Structure

```
discuss/
├── lib/
│   ├── discuss.ex                 # Application entry point
│   ├── discuss/
│   │   ├── endpoint.ex            # Phoenix endpoint config
│   │   └── repo.ex                # Ecto repository
├── web/
│   ├── controllers/               # Business logic handlers
│   ├── views/                     # View modules (with template compiler macro)
│   ├── templates/                 # EEx HTML templates
│   ├── channels/                  # WebSocket channels
│   ├── models/                    # Ecto schemas
│   └── router.ex                  # Route definitions
├── config/
│   ├── config.exs                 # Base configuration
│   ├── dev.exs                    # Development configuration
│   ├── prod.exs                   # Production configuration
│   ├── esbuild.exs                # JavaScript bundler config
│   └── tailwind.exs               # CSS compiler config
├── priv/
│   └── static/
│       └── assets/                # Compiled assets
├── tailwind.config.js             # Tailwind CSS configuration
└── package.json                   # npm dependencies
```

---

## 🗄️ Database Schema

### Users
- `id` - Primary key
- `email` - User email address
- `provider` - OAuth provider (github)
- `uid` - Provider user ID
- `inserted_at` / `updated_at` - Timestamps

### Topics
- `id` - Primary key
- `title` - Topic title
- `user_id` - Creator user ID
- `inserted_at` / `updated_at` - Timestamps

### Comments
- `id` - Primary key
- `content` - Comment text
- `user_id` - Author user ID
- `topic_id` - Parent topic ID
- `inserted_at` / `updated_at` - Timestamps

---

## 🔐 Authentication

Discuss uses **GitHub OAuth** for authentication:

1. Users click "Sign in with GitHub"
2. Redirected to GitHub's OAuth endpoint
3. GitHub redirects back with authorization code
4. Application exchanges code for user data
5. User is created/updated in database
6. Session is established

**Sensitive data** (email, user ID) is protected and never logged. See [GITHUB_AUTH_FIX.md](./GITHUB_AUTH_FIX.md) for OAuth configuration details.

---

## 🌐 Real-time Features

WebSocket channels enable real-time discussions:

```elixir
socket = Socket.join("comments:topic_id")
socket.on("new_comment", callback)
```

Comments appear instantly for all connected users in the same topic discussion.

---

## 📊 Architecture Decisions

### Why Traditional Architecture (Not LiveView)?

While Phoenix LiveView is powerful, this project maintains the traditional **Controllers → Views → Templates** pattern for:

- ✅ **Clarity** - Clear separation of concerns
- ✅ **Learning** - Educational value for beginners
- ✅ **Flexibility** - Easy to add LiveView components later
- ✅ **Performance** - Static HTML rendering with WebSocket enhancements
- ✅ **Maintainability** - Well-known patterns and conventions

### DRY Principles

The codebase applies Elixir's **macro metaprogramming** to eliminate boilerplate:

```elixir
# Before (repeated in 3 view files)
def render(template, assigns) do
  # Template compilation logic...
end

# After (using Discuss.TemplateCompiler macro)
require Discuss.TemplateCompiler
Discuss.TemplateCompiler.compile_templates("path/to/templates")
```

This approach provides a **single source of truth** for template compilation logic while maintaining zero runtime overhead (macros execute at compile-time).

See [DRY_IMPROVEMENTS.md](./DRY_IMPROVEMENTS.md) for detailed analysis.

---

---

## 🚢 Deployment

### Fly.io (Recommended) ⭐

Fly.io is a modern deployment platform perfect for Phoenix applications with built-in PostgreSQL support and global edge cache.

#### Prerequisites
- Install [Flyctl CLI](https://fly.io/docs/getting-started/installing-flyctl/)
- Create a [Fly.io account](https://fly.io/)
- PostgreSQL addon (automatically added)

#### Deployment Steps

```bash
# 1. Install Fly.io CLI
# macOS
brew install flyctl

# Linux
curl https://fly.io/install.sh | sh

# 2. Authenticate with Fly.io
flyctl auth login

# 3. Launch your app (from project root)
flyctl launch --name discuss-app

# This will:
# - Create a fly.toml configuration file
# - Create a Dockerfile (if not present)
# - Ask about PostgreSQL addon (select YES)
# - Ask about additional regions

# 4. Set environment variables
flyctl secrets set GITHUB_CLIENT_ID=your_id
flyctl secrets set GITHUB_CLIENT_SECRET=your_secret
flyctl secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)

# 5. Deploy your app
flyctl deploy

# 6. Run migrations (first time only)
flyctl ssh console -C "app eval 'Discuss.Release.migrate()'"

# 7. View live logs
flyctl logs

# 8. Monitor your app
flyctl monitor
```

#### Scale Your App
```bash
# Check current status
flyctl status

# Scale machines (add more power)
flyctl scale vm shared-cpu-1x --count 2

# Deploy new version
flyctl deploy
```

#### Useful Commands
```bash
# View app information
flyctl info

# SSH into the app
flyctl ssh console

# Stop/pause the app
flyctl pause

# Resume the app
flyctl resume

# View secrets
flyctl secrets list

# Update a secret
flyctl secrets set VARIABLE_NAME=new_value

# Remove a secret
flyctl secrets unset VARIABLE_NAME
```

**See [Fly.io Phoenix Documentation](https://fly.io/docs/getting-started/get-started-elixir/) for more details.**

---

### Heroku (Alternative)

```bash
# 1. Install Heroku CLI
brew install heroku/brew/heroku

# 2. Login to Heroku
heroku login

# 3. Create Heroku app
heroku create discuss-app

# 4. Add PostgreSQL addon
heroku addons:create heroku-postgresql:standard-0

# 5. Set environment variables
heroku config:set GITHUB_CLIENT_ID=xxx
heroku config:set GITHUB_CLIENT_SECRET=xxx
heroku config:set SECRET_KEY_BASE=$(mix phx.gen.secret)

# 6. Deploy
git push heroku master

# 7. Run migrations
heroku run "mix ecto.migrate"

# 8. Open app
heroku open
```

---

### Docker (Self-Hosted)

Build and run with Docker:

```dockerfile
# Dockerfile
FROM elixir:1.17

WORKDIR /app

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Copy files
COPY . .

# Install dependencies
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    npm install

# Build assets
RUN mix assets.deploy

# Expose port
EXPOSE 4000

# Set environment
ENV MIX_ENV=prod

# Start app
CMD ["mix", "phx.server"]
```

Build and run:
```bash
docker build -t discuss:latest .
docker run -p 4000:4000 \
  -e DATABASE_URL=postgresql://user:pass@db:5432/discuss \
  -e GITHUB_CLIENT_ID=xxx \
  -e GITHUB_CLIENT_SECRET=xxx \
  discuss:latest
```

---

### Environment Variables

Regardless of deployment platform, ensure these variables are set:

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | ✅ |
| `SECRET_KEY_BASE` | Session encryption key (generate: `mix phx.gen.secret`) | ✅ |
| `GITHUB_CLIENT_ID` | OAuth app client ID | ✅ |
| `GITHUB_CLIENT_SECRET` | OAuth app client secret | ✅ |
| `PHX_HOST` | Public domain name | ✅ |
| `PHX_PORT` | Port (usually 4000) | ❌ (default: 4000) |

**Generate a secure SECRET_KEY_BASE:**
```bash
mix phx.gen.secret
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Elixir conventions via `mix format`
- Use meaningful variable names
- Comment only when clarifying complex logic
- Write tests for new features

---

## 📝 License

This project is open source and available under the MIT License.

---

## 🔗 Resources & Links

### Framework Documentation
- 🌐 [Phoenix Official Website](https://www.phoenixframework.org/)
- 📖 [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- 🎓 [Phoenix Documentation](https://hexdocs.pm/phoenix/)
- 🧠 [Elixir Documentation](https://hexdocs.pm/elixir/)

### Tools & Frameworks
- ⚡ [esbuild - JavaScript Bundler](https://esbuild.github.io/)
- 🎨 [Tailwind CSS - Utility-first CSS](https://tailwindcss.com/)
- 🔐 [Ueberauth - Authentication Library](https://github.com/ueberauth/ueberauth)
- 🗄️ [Ecto - Database Toolkit](https://hexdocs.pm/ecto/)

### Learning Resources
- 📚 [Elixir School](https://elixirschool.com/)
- 🎥 [Phoenix Framework Tutorials](https://www.phoenixframework.org/blog)
- 💬 [Phoenix Forum](https://elixirforum.com/)
- 🐦 [Elixir Community](https://elixir-lang.org/community)

---

## 🐛 Troubleshooting

### Database Connection Error
```bash
# Ensure PostgreSQL is running
# macOS with Homebrew:
brew services start postgresql

# Create/reset database:
mix ecto.drop
mix ecto.create
mix ecto.migrate
```

### Asset Compilation Issues
```bash
# Clear compiled assets
rm -rf priv/static/assets

# Rebuild
mix assets.build
```

### OAuth Authentication Not Working
See [GITHUB_AUTH_FIX.md](./GITHUB_AUTH_FIX.md) for detailed OAuth troubleshooting.

---

## 📈 Project Status

- ✅ **Version**: 0.0.1
- ✅ **Phoenix**: 1.7.21 (Latest)
- ✅ **Elixir**: 1.17.2 (Latest)
- ✅ **Status**: Active Development
- ✅ **Production Ready**: Yes

---

## 👨‍💻 Author

Built with ❤️ by [Mingyar Furtado](https://github.com/mingyar)

---

**Made with Phoenix ❤️ and Elixir**
