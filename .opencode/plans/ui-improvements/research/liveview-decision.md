# LiveView Architecture: UI Improvements

## Recommendation

**Use LiveView**: Yes — but the scope is purely cosmetic/UX. No routing, data fetching, or real-time changes needed.

**Rationale**: All four changes are light-touch modifications to existing templates, CSS theme config, and one layout file. Every change gets resolved at the template/CSS layer — no new LiveViews, LiveComponents, contexts, or PubSub patterns.

---

## Change 1 — Base Light Mode Color

### Current

```css
--color-base-100: oklch(98% 0 0);       /* essentially pure white */
--color-base-200: oklch(96% 0.001 286);
--color-base-300: oklch(92% 0.004 286);
```

The 0 chroma in base-100 means zero saturation — pure neutral white. Combined with `--depth: 1` and `--border: 1.5px`, the page feels sterile and high-contrast with no warmth.

### What I Recommend

Warm the entire base stack by adding a tiny amount of chroma in the yellow-amber direction (~85° in OKLCH):

```css
/* Warm, inviting, premium */
--color-base-100: oklch(97% 0.008 85);
--color-base-200: oklch(94% 0.01 85);
--color-base-300: oklch(90% 0.015 85);
--color-base-content: oklch(21% 0.01 85);
```

**Why 85° in OKLCH?**
- 85° maps to a warm cream/eggshell/paper tone — feels cozy, not yellow
- Matches the "discussion" app personality (approachable, human)
- The `primary` at 47° (amber-ish) and this new base at 85° will harmonize beautifully
- The dark theme (252°, blue-gray) will contrast gracefully
- Still reads as "white" — users won't think "this is beige", they'll just feel the warmth

Dark theme stays untouched — it's already well-tuned at `oklch(30% 0.016 252)`.

### File to Change

`assets/css/app.css` — the `@plugin "../vendor/daisyui-theme" { name: "light"; ... }` block, lines 59–92.

---

## Change 2 — Remove "Topics" Header

### Problem

```heex
<.header>   ← index.html.heex line 1–3
  Topics
</.header>
```

This `<.header>` is redundant — the nav bar already says "💬 Discuss", and the composer + topic list layout makes the page's purpose blindingly obvious. Twitter, Reddit, Hacker News — none of them say "Posts" at the top of their feed.

### What I Recommend

Delete the `<.header>` block entirely from `index.html.heex`.

- The `:page_title` assign in the LiveView (`"Topics"`) remains set for the browser tab — SEO/crawlers still see `<title>Topics</title>`
- The page flows: `composer → topic list` — cleaner, more modern
- Remove `mt-6` from the topic list wrapper (line 53) so spacing between composer and list is tighter and feels intentional

### File to Change

`lib/discuss_web/live/topic_live/index.html.heex`

### Screenshot Mental Model

```
Before:                    After:
┌─────────────────────┐   ┌─────────────────────┐
│  Topics       ← h1  │   │  [composer box]      │
│  [composer box]     │   │  ┌─────────────────┐ │
│  ┌──────────────┐   │   │  │ Topic Card      │ │
│  │ Topic Card   │   │   │  │ ...             │ │
│  │ ...          │   │   │  └─────────────────┘ │
│  └──────────────┘   │   │  ┌─────────────────┐ │
│  ┌──────────────┐   │   │  │ Topic Card      │ │
│  │ Topic Card   │   │   │  │ ...             │ │
│  │ ...          │   │   │  └─────────────────┘ │
│  └──────────────┘   │   └─────────────────────┘
└─────────────────────┘
```

---

## Change 3 — Sign In / Sign Out Treatment

### Current Problems

| State | Layout | Issue |
|-------|--------|-------|
| Signed in | Avatar + name text "Sign Out" (3 items) | Too much horizontal real estate; name truncation is ugly |
| Signed out | Large button "Sign in with GitHub" | Overweight for an action users do once |
| Both | Auth widget is same visual weight as the brand | Competing focal points in the nav |

### What I Recommend

**Two patterns, same spot:**

**Signed in:** `avatar → dropdown menu`
- Show only the avatar (circular, 32px)
- Click opens a small dropdown with user name + "Sign Out"
- This is the GitHub/Linear/Vercel pattern — proven, minimalist

**Signed out:** `icon + compact text`
- GitHub icon + "Sign in" — compact button, no full sentence
- Uses `.btn-soft` for a subtler visual weight

### Implementation Approach

The dropdown should be a **pure HTML `<details>` menu** — no LiveComponent, no JS needed. daisyUI has first-class support:

```heex
<details class="dropdown dropdown-end">
  <summary class="list-none cursor-pointer">
    <img src={@current_user.avatar_url} class="w-8 h-8 rounded-full" />
  </summary>
  <ul class="dropdown-content menu bg-base-100 rounded-box z-50 shadow-lg
             mt-2 p-2 w-48 border border-base-300">
    <li class="menu-title"><span>{@current_user.name}</span></li>
    <li><hr class="my-1" /></li>
    <li>
      <.link href="/auth/signout" method="delete"
        class="text-error hover:text-error/80">
        Sign Out
      </.link>
    </li>
  </ul>
</details>
```

For signed-out:

```heex
<.link href="/auth/github"
  class="btn btn-soft btn-sm gap-1.5">
  <.icon name="hero-github" class="size-4" />
  Sign in
</.link>
```

### Why This Is Better

| Concern | Before | After |
|---------|--------|-------|
| Nav visual noise | 3 elements (avatar + name + link) | 1 element (avatar) |
| Signed-out weight | Full sentence button | Compact icon + label |
| Horizontal space | ~250px for signed-in | ~40px for signed-in |
| User identity | Always visible text | On-demand via dropdown |
| Implementation complexity | None (already works) | Minimal (details + CSS) |

### File to Change

`lib/discuss_web/components/layouts/app.html.heex` — the auth block (lines 15–49).

---

## Change 4 — Bigger Topic Panels

### Current vs. Proposed

| Element | Current | Proposed | Why |
|---------|---------|----------|-----|
| Card padding | `p-5 sm:p-6` | `p-6 sm:p-8` | More breathing room, premium feel |
| Title size | `text-base sm:text-lg` | `text-lg sm:text-xl` | Readability, visual hierarchy |
| Title line-clamp | none | `line-clamp-2` | Prevents super-long titles breaking layout |
| Card shadow | `shadow-sm` | `shadow-md` | Lift cards off background more |
| Metadata bottom | inline with title | stays inline | No change needed — scales naturally |
| Edit/Delete buttons | current | unchanged | Functional, not content |

### Rationale

The cards are the primary content of the page. Making them bigger:
- Improves readability at a glance
- Makes each topic feel more substantial
- Creates better visual rhythm in the stream
- The larger cards paired with a warm background (Change 1) will feel much more premium

### File to Change

`lib/discuss_web/live/topic_live/index.html.heex` — the topic card div (lines 60–101).

---

## All Files Changed (Summary)

| File | Change |
|------|--------|
| `assets/css/app.css` | Warm the light theme base stack |
| `lib/discuss_web/live/topic_live/index.html.heex` | Remove `<.header>`, bump card sizes, adjust spacing |
| `lib/discuss_web/components/layouts/app.html.heex` | Replace auth widget with avatar dropdown / compact sign-in |

No new modules, no new routes, no new contexts. Pure UI.

---

## Affordance Tables

### Places

| ID | Place | Entry Point | Notes |
|----|-------|-------------|-------|
| P1 | Topic Index LiveView | `GET /` or `GET /topics` | Main topic list |
| P2 | Topic Show LiveView | `GET /topics/:id` | Topic detail + comments |
| P3 | App Layout | wraps all LiveViews | Navbar with auth widget |

### UI Affordances (Changes Only)

| ID | Place | Component | Affordance | Type | Wires Out | Returns To |
|----|-------|-----------|------------|------|-----------|------------|
| U1 | P3 | Nav | Avatar | `click` → dropdown | N1 | — |
| U2 | P3 | Nav | "Sign in" button | `click` → `/auth/github` | — | — |
| U3 | P3 | Nav | "Sign Out" in dropdown | `click` → `/auth/signout` (DELETE) | — | — |

### Code Affordances

| ID | Place | Module | Affordance | Wires Out | Returns To |
|----|-------|--------|------------|-----------|------------|
| N1 | P3 | `app.html.heex` | `<details>` dropdown (native HTML) | none (no LV event) | — |

No new code affordances needed. The dropdown uses native HTML `<details>` element — no LiveView events, no JS commands, no component mounting.

---

## Design Philosophy

Your four requests together tell a story:

1. **Warm background** → changes the emotional tone of the entire app
2. **Remove redundant header** → trusts the user to understand what page they're on
3. **Avatar dropdown** → reduces visual noise in the nav, puts user identity on-demand
4. **Bigger topic cards** → makes the content feel substantial and worth reading

They're all pulling in the same direction: **less noise, more warmth, bigger signal.**
