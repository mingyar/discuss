# Discuss — Plan

## Source of Truth

All known issues and planned work are tracked on GitHub:
https://github.com/mingyar/discuss/issues

Bug labels: `priority: critical`, `priority: high`, `priority: medium`, `priority: low`
Tech debt label: `tech-debt`

## Architecture Decisions

_Add entries here when you make a non-obvious design choice._

- **Inline composer instead of separate form** — The `/topics/new` route redirects to Index immediately. Creation happens via the inline composer on the Index page. The old `FormComponent` was left as dead code after this change.

- **Topic broadcasts go to two channels** — Topic creates/updates/deletes are broadcast to both `"topics"` (for Index) and `"topic:#{id}"` (for Show). This way both LiveViews stay in sync without subscribing to each topic individually on the Index page.

## Notes

- `FormComponent` is dead code — the inline composer replaced it. See #41.
- `FadeIn` JS hook is defined in `hooks.js` but never used. See #40.
