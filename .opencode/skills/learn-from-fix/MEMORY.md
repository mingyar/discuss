# Lessons Learned

## Deployment: Fly.io + Neon (IPv4 DB on IPv6-only infra)

### Lesson 1: DNS64 is NOT available on Fly.io — use `getent` for IPv4 resolution
- **Pattern**: Do NOT rely on Fly.io IPv6 DNS to resolve IPv4-only hostnames. Fly.io's DNS at `fdaa::3` does NOT do DNS64 synthesis (returns NXDOMAIN for A-only records when queried over `AF_INET6`).
- **Why**: Fly.io machines are IPv6-only. `getaddrinfo` with `AF_INET6` (Erlang's default on IPv6 machines) won't return IPv4 A records. The OS resolver works fine via `getent hosts`, which returns the raw IPv4.
- **Fix**: Use `System.cmd("getent", ["hosts", hostname])` to resolve, then substitute the IP into connection URLs.

### Lesson 2: Raw IP in DB URL breaks SSL hostname verification
- **Pattern**: Do NOT replace a hostname with a raw IP in a DB connection URL without also fixing SSL verification. The SSL certificate won't have an IP SAN — it has DNS names (e.g., `*.c-2.us-east-1.aws.neon.tech`).
- **Why**: Erlang's SSL hostname verification checks the cert's DNS names against the `server_name_indication` value. When connecting to a raw IP, the default SNI is the IP, which never matches the cert.
- **Fix**: Pass the original hostname via `server_name_indication` in `ssl_opts`. In Postgrex 0.22+, use the keyword list form:
  ```elixir
  ssl: [cacerts: :public_key.cacerts_get(), server_name_indication: to_charlist(original_host)]
  ```

### Lesson 3: Postgrex 0.22 deprecated `ssl_opts` config key
- **Pattern**: Do NOT use `ssl: true, ssl_opts: [...]` in Postgrex 0.22+. The deprecated path uses your opts AS-IS without adding `cacerts` or `verify`, causing Erlang SSL to reject `{verify, verify_peer}` + `{cacerts, undefined}`.
- **Why**: Postgrex 0.22 changed how SSL options work. The old `ssl_opts:` key is deprecated. The new API merges user opts on top of secure defaults via `Keyword.merge`.
- **Fix**: Pass opts directly inside `ssl:` as a keyword list:
  ```elixir
  # Old (broken in 0.22):
  ssl: true,
  ssl_opts: [server_name_indication: ...]

  # New (correct):
  ssl: [cacerts: :public_key.cacerts_get(), server_name_indication: ...]
  ```
  When `ssl:` is a keyword list, Postgrex merges with `[verify: :verify_peer, customize_hostname_check: [...]]` automatically.

### Lesson 4: `force_ssl` breaks health checks on Fly.io
- **Pattern**: Do NOT use Phoenix-level `force_ssl` (Plug.SSL) on Fly.io. It redirects ALL HTTP to HTTPS, including Fly.io's internal health check requests which are sent as plain HTTP.
- **Why**: Two problems with the exclude mechanism:
  1. Phoenix endpoint's `exclude` key is at the wrong level — only `force_ssl` is passed to Plug.SSL. The `exclude` at the endpoint level is never read.
  2. Plug.SSL's `:exclude` option only supports **hosts**, not paths. You cannot exclude `/health` by path.
- **Fix**: Remove `force_ssl` entirely when deploying on Fly.io. Fly.io proxy already handles HTTPS termination (`force_https = true` in `fly.toml`), HSTS headers, and HTTP→HTTPS redirect. The app receives plain HTTP internally.

### Lesson 5: Build Elixir releases on runner, Docker packages only
- **Pattern**: Do NOT build Elixir releases inside Docker for Fly.io deployments. Build on the GitHub Actions runner (which has working OTP httpc), then use Docker with `ubuntu:24.04` to package the pre-built release.
- **Why**: The OTP httpc TLS client fails inside Docker (`key_usage_mismatch` on `builds.hex.pm`) due to missing/broken CA bundle. The runner has no such issue. Also, `ubuntu:24.04` must match the runner's GLIBC version (2.39) to avoid "GLIBC not found" errors on the ERTS binary.
- **Fix**: `.github/workflows/deploy.yml` — `mix deps.get && mix compile && mix assets.deploy && mix release` on runner, then `flyctl deploy --local-only` (uses Dockerfile to package the release artifact).
