# Discuss — Audit & Development Plan

> Generated from a systematic codebase audit against 5 core requirements.

---

## 🔐 GitHub OAuth Authentication

**Status: ✅ Implemented (with gaps)**

### What Works
- OAuth callback handles success and failure paths with flash messages
- `signout/2` drops session via `configure_session(drop: true)`
- `SetUser` plug loads `current_user` on every request (in `:browser` pipeline)
- `UserAuth` LiveView mount hook loads user from session on every LiveView
- Nav UI shows avatar, name, sign in/out — clean and functional
- `find_or_create_user/1` correctly uses `provider` + `uid` composite lookup
- User schema has all needed OAuth fields (`provider`, `uid`, `token`, `avatar_url`, `name`)

### Gaps to Fix

| # | Priority | Issue | Fix |
|---|----------|-------|-----|
| 1 | 🔴 **CRITICAL** | **No route protection.** `require_auth` pipeline defined but never used. `:require_authenticated_user` hook is dead code. Any visitor can access all topic CRUD. | Apply `require_auth` pipeline to topic routes OR wrap routes in `live_session` with the mount hook |
| 2 | 🔴 **HIGH** | **Missing unique indexes** on `users` table for `email` and `[:provider, :uid]`. `unique_constraint` silently no-ops. Race conditions can create duplicates. | New migration: `create unique_index(:users, [:email])` and `create unique_index(:users, [:provider, :uid])` |
| 3 | 🟡 **MEDIUM** | **`find_or_create_user/1` uses `.` access on maps** (`attrs.provider`). Crashes if called with string keys instead of atom keys. | Change to `Map.fetch!/2` or pattern match on `%{provider: _, uid: _}` in function head |
| 4 | 🟡 **MEDIUM** | **No tests** for auth flow — no auth_controller_test, no user_auth_test, no plug tests, no accounts_test for `find_or_create_user` | Write tests covering success, failure, signout, and route protection |
| 5 | 🟢 **LOW** | **Signout only works with JS.** Without JS, "Sign Out" hits the Ueberauth `request` action and redirects to GitHub. | Add GET or POST fallback route for signout |
| 6 | 🟢 **LOW** | **`callback_url` not configured** for Ueberauth. May cause issues behind proxies in production. | Add `callback_url` to Ueberauth GitHub config |

---

## 💬 Real-time Discussions

**Status: ✅ Implemented (comments only, not topics)**

### What Works
- `subscribe_to_topic/1` uses correct topic pattern `"topic:#{topic_id}"`
- Comment creation broadcasts `:comment_created` via PubSub
- Comment deletion broadcasts `:comment_deleted` via PubSub
- `connected?` guard properly prevents double subscription in `mount/3`
- `handle_info` clauses correctly `stream_insert` / `stream_delete` comments
- Both `comments_count` and stream are atomically updated
- 3 unit tests (`discussions_test.exs`) and 3 integration tests (`topic_live_test.exs`) cover real-time comment flow

### Gaps to Fix

| # | Priority | Issue | Fix |
|---|----------|-------|-----|
| 7 | 🟡 **MEDIUM** | **Topic edits are not broadcast.** Only the editing user sees changes (via `push_patch` remount). Other viewers see stale data. | Add `broadcast_topic_update/2` in Discussions context, subscribe on Show LiveView mount, add `handle_info({:topic_updated, topic})` |
| 8 | 🟢 **LOW** | **`handle_info({FormComponent, {:saved, topic}})` on index uses `at: 0`** — moves edited topic to top of list instead of updating in place. | Use `stream_insert(:topics, topic)` without `at: 0` for edits (keep `at: 0` only for new creates) |

---

## 📝 Topic Management

**Status: ✅ Implemented (2 gaps found)**

### What Works
- Full CRUD: create (inline composer), read (index + show), update (edit modal), delete (with ownership check)
- Streams used correctly for both topics and comments
- Inline composer works end-to-end with success flash and form reset
- Ownership enforced at context level for `delete_topic_by_user/2`
- Graceful 404 for non-existent topic on Show page (redirects with flash)
- Edit modal on both index and show pages
- Empty states for both topics and comments with CSS-only pattern

### Gaps to Fix

| # | Priority | Issue | Fix |
|---|----------|-------|-----|
| 9 | 🔴 **HIGH** | **Update has no ownership check.** `update_topic/2` accepts any `%Topic{}` and attrs. UI hides Edit button from non-owners but no server-side enforcement. | Add `update_topic_by_user/3` (like `delete_topic_by_user/2`) with pattern match on `user_id` |
| 10 | 🟡 **MEDIUM** | **`get_topic!` in edit/delete handlers crashes on missing topics.** Edit `apply_action` and delete `handle_event` use `get_topic!` which raises `Ecto.NoResultsError`. | Switch to `get_topic/1` + nil guard with flash and redirect (like Show page already does) |
| 11 | 🟢 **LOW** | **No validation errors in inline composer.** Raw `<input>` doesn't display Ecto changeset errors. Blank/title-too-short submissions show no feedback. | Replace raw `<input>` with `<.input>` component, or add a dedicated error display, or at least show a flash on error |
| 12 | 🟢 **LOW** | **No success flash on topic delete.** User gets no confirmation. | Add `put_flash(:info, "Topic deleted")` in the success branch |
| 13 | 🟢 **LOW** | **No topic delete on Show page.** Users must navigate back to index to delete. | Design decision — could add a delete button on show page |
| 14 | 🟢 **LOW** | **Route path `/topics/:id/show/edit` is unconventional.** | Consider `/topics/:id/edit` for the show-page edit route |

---

## 👥 User System

**Status: ✅ Implemented (2 minor gaps)**

### What Works
- `name` field used consistently with `|| email` fallback everywhere
- User schema has all OAuth fields with proper changeset validations
- `get_user/1` safe variant exists and is used by plugs/auth hooks
- Avatars displayed where expected
- Test fixtures provide valid user attributes

### Gaps to Fix

| # | Priority | Issue | Fix |
|---|----------|-------|-----|
| 15 | 🟡 **MEDIUM** | **No avatar fallback in nav and comment list.** When `avatar_url` is nil, the `<img>` simply doesn't render, creating a visual gap. | Add fallback avatar (ui-avatars.com or CSS initials) in `app.html.heex` and `show.html.heex` |
| 16 | 🟢 **LOW** | **`FadeIn` JS hook is defined but never used.** | Remove or wire into templates |

---

## 🎨 Responsive UI

**Status: ✅ Implemented (2 minor gaps)**

### What Works
- Responsive padding/sizing on all cards, composer, and modals
- Brand name swaps from emoji to full text at `sm:` breakpoint
- User name hidden on mobile (avoids overflow)
- Theme system uses localStorage, `prefers-color-scheme` detection, cross-tab sync, and blocking script to prevent flash
- All HEEx templates use daisyUI theme tokens — zero hardcoded colors in templates
- Focus-visible accessibility rings
- Fade-out transitions on delete

### Gaps to Fix

| # | Priority | Issue | Fix |
|---|----------|-------|-----|
| 17 | 🟡 **MEDIUM** | **Theme toggle hidden on mobile** (`hidden sm:block`). Mobile users cannot switch themes. | Show a compact mobile-friendly toggle, or always show it |
| 18 | 🟢 **LOW** | **Hardcoded `ring-blue-500`** in `app.css` focus-visible styles — doesn't respect theme. | Replace with daisyUI semantic token like `ring-primary` |

---

## Consolidated Priority List

### 🔴 Critical (fix now)
1. **Route protection** — nothing is guarded; any visitor can CRUD topics
2. **Missing unique indexes** — duplicate users possible

### 🟡 High (fix soon)
3. **Update ownership check** — `update_topic/2` has no server-side enforcement
4. **Missing topic edit broadcast** — other users don't see live updates
5. **`get_topic!` crash risk** — edit/delete handlers crash on missing topics
6. **No auth tests** — entire auth flow is untested
7. **`find_or_create_user` fragile key access**
8. **No avatar fallback** in nav and comments
9. **Theme toggle hidden on mobile**

### 🟢 Medium/Low (fix when convenient)
10. Inline composer validation errors not displayed
11. `stream_insert(..., at: 0)` reorders on edit
12. No delete success flash
13. Hardcoded `ring-blue-500` in app.css
14. Signout only works with JS
15. `callback_url` not configured
16. `FadeIn` hook unused

---

## Test Coverage Summary

| Area | Tests | Missing |
|------|-------|---------|
| Topics CRUD (Index) | 7 tests | Edit flow, invalid input, non-existent topic redirect |
| Topics CRUD (Show) | 3 tests (real-time) | Topic display, comments CRUD (only real-time covered) |
| Real-time comments | 3 unit + 3 integration | Edge cases (late subscription, stale data) |
| **Authentication** | **0 tests** | **Entirely missing** |
| Accounts context | 0 tests | `find_or_create_user`, `get_user` |
| User schema | 0 tests | Changeset validations, unique constraints |
