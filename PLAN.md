# Discuss - Development Plan

## 💬 Real-time Discussions
- [ ] **Comment editing** — inline edit form + `handle_event("edit_comment")` in show LiveView
- [ ] **Topic edit broadcast** — PubSub broadcast when topic title changes so other viewers see it live

## 📝 Topic Management
- [ ] **Topic body/content** — migration to add `:description` text column, update schema/changeset, display in show template

## 👥 User System
- [x] **GitHub OAuth** — Ueberauth, SetUser/RequireAuth plugs, UserAuth hooks, AuthController
- [ ] **Fix nickname schema bug** — migration exists but `field :nickname, :string` missing from User schema (crashes in navbar)
- [ ] **User profile page** — `/users/:id` showing avatar, name, join date, their topics

## 🎨 Responsive UI
- [x] Tailwind v4 + daisyUI, responsive nav/cards, light/dark/system theme, micro-animations
- [ ] Ongoing visual polish

## Priority
1. 🔴 Fix nickname schema bug
2. ➕ Add topic body field
3. ✏️ Add comment editing
4. 👤 User profile page
5. 📡 Topic edit broadcast
6. 🎨 Visual polish
