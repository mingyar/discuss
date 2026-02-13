# Complete List of Changes - Phoenix 1.6 → 1.7 Upgrade with Tailwind

## Summary
Upgraded Discuss from Phoenix 1.6.16 to 1.7.21 with modern asset pipeline (esbuild + Tailwind), fixed template rendering, and added OAuth authentication error handling.

## Modified Files

### Configuration Files
- **mix.exs**
  - Updated Phoenix from 1.6.0 to 1.7.0
  - Updated Phoenix HTML from 3.0 to 4.0
  - Added phoenix_html_helpers 1.0
  - Added esbuild 0.7 (dev only)
  - Added tailwind 0.2 (dev only)
  - Updated compilers from [:phoenix, :gettext] to Mix.compilers
  - Added aliases: setup, assets.deploy

- **package.json**
  - Removed Brunch dependencies (babel-brunch, brunch, clean-css-brunch, uglify-js-brunch)
  - Changed deploy script from "brunch build --production" to "mix assets.deploy"
  - Removed watch script
  - Added esbuild 0.20.0
  - Added tailwindcss 3.4.0

- **config/config.exs**
  - Changed from `use Mix.Config` to `import Config`
  - Added esbuild configuration
  - Added tailwind configuration
  - Updated Ueberauth GitHub strategy with scope: "user:email"

- **config/dev.exs**
  - Changed from `use Mix.Config` to `import Config`
  - Updated watchers to use esbuild and tailwind instead of Brunch
  - Updated watchers to use install_and_run pattern

- **config/prod.exs**
  - Changed from `use Mix.Config` to `import Config`

- **config/test.exs**
  - Changed from `use Mix.Config` to `import Config`

### New Configuration Files
- **config/esbuild.exs** (NEW)
  - Configures esbuild for JavaScript bundling
  - Points to priv/static/js/app.js as input
  - Outputs to priv/static/assets/app.js

- **config/tailwind.exs** (NEW)
  - Configures Tailwind CSS compiler
  - Points to priv/static/css/app.css as input
  - Outputs to priv/static/assets/app.css

- **tailwind.config.js** (NEW)
  - Tailwind configuration
  - Content paths include web/templates and web/views
  - Theme and plugins configuration

### View & Controller Files
- **web/web.ex**
  - Removed Phoenix.View import
  - Updated imports to use Phoenix.HTML and PhoenixHTMLHelpers
  - Added render/3 helper function for backward compatibility with template rendering

- **web/views/topic_view.ex**
  - Replaced `use Phoenix.View` with manual template compilation
  - Uses Phoenix.Template.EExEngine.compile/2 to compile templates at build time
  - Includes all templates from web/templates/topic/

- **web/views/page_view.ex**
  - Same template compilation pattern as TopicView
  - Includes all templates from web/templates/page/

- **web/views/layout_view.ex**
  - Same template compilation pattern
  - Includes all templates from web/templates/layout/

- **web/views/error_helpers.ex**
  - Changed from `use Phoenix.HTML` to `use PhoenixHTMLHelpers`
  - Updated for Phoenix HTML 4.0 compatibility

- **web/controllers/auth_controller.ex**
  - Added fallback clause for ueberauth_failure
  - Added defensive email fallback logic:
    1. Uses auth.info.email if available
    2. Falls back to auth.info.nickname
    3. Uses generated email based on user ID as last resort

### Template Files
- **web/templates/layout/app.html.eex**
  - Updated asset paths from /css/app.css and /js/app.js to /assets/app.css and /assets/app.js
  - Changed layout rendering from `<%= render @view_module, @view_template, assigns %>` to `<%= @inner_content %>` (Phoenix 1.7 standard)
  - Updated get_flash calls (deprecated but still functional)

### Frontend Files
- **web/static/css/app.css** → **priv/static/css/app.css**
  - Added @tailwind directives at the top (base, components, utilities)
  - Preserved custom CSS rules

- **web/static/js/app.js** → **priv/static/js/app.js**
  - Copied to new location (unchanged content)

## Created Files

- **PHOENIX_UPGRADE.md** - Comprehensive upgrade guide
- **UPGRADE_SUMMARY.md** - Quick summary of changes
- **GITHUB_AUTH_FIX.md** - Authentication fix documentation
- **CHANGES.md** - This file (complete change log)

## Removed Files

- **brunch-config.js** - Brunch configuration (no longer needed)

## Directory Structure Changes

### Before
```
web/static/
  ├── css/
  │   ├── app.css
  │   └── phoenix.css
  ├── images/
  ├── js/
  │   ├── app.js
  │   └── socket.js
  └── ...
```

### After
```
priv/static/
  ├── assets/
  │   ├── app.css (compiled from Tailwind)
  │   └── app.js (bundled by esbuild)
  ├── css/
  │   ├── app.css (source)
  │   └── phoenix.css
  ├── js/
  │   ├── app.js (source)
  │   └── socket.js
  └── ...
```

## Dependencies Changes

### Added
- phoenix_html_helpers ~> 1.0
- esbuild ~> 0.7 (dev only)
- tailwind ~> 0.2 (dev only)

### Updated
- phoenix: 1.6.0 → 1.7.0
- phoenix_html: 3.0 → 4.0
- phoenix_pubsub: 2.0 → 2.1
- phoenix_ecto: 4.5 → 4.4 (minor version)
- Several other dependencies auto-updated by Mix

### Removed
- babel-brunch
- brunch
- clean-css-brunch
- uglify-js-brunch

## Key Behavior Changes

1. **Asset Compilation**
   - Now uses esbuild (much faster)
   - CSS goes through Tailwind compiler
   - Output to priv/static/assets/ instead of priv/static/js/ and /css/

2. **Template Discovery**
   - Templates are now compiled at build time
   - No longer auto-discovered from disk at runtime
   - Must be explicitly compiled in view modules

3. **Layout Rendering**
   - Changed from explicit render call to implicit @inner_content
   - More efficient and idiomatic for Phoenix 1.7

4. **Authentication**
   - GitHub OAuth now requests user:email scope
   - Graceful fallback when email is unavailable
   - Proper error handling for OAuth failures

5. **Configuration**
   - Modern `import Config` syntax
   - esbuild and tailwind watchers instead of Brunch

## Testing & Verification

All changes have been tested:
- ✅ Code compiles without errors
- ✅ Server starts successfully
- ✅ Pages render correctly
- ✅ Assets load from correct paths
- ✅ Database queries work
- ✅ Authentication error handling works
- ✅ OAuth email scope requests work

## Migration Guide for Developers

If you need to add new templates:
1. Create template file: `web/templates/my_view/action.html.eex`
2. Update the corresponding view file to include it in the compilation loop
3. Recompile: `mix compile`
4. Call from controller: `render conn, "action.html", variable: value`

If you need to add new Tailwind styles:
1. Add classes to your template: `<div class="bg-blue-500 text-white p-4">`
2. Tailwind compiler automatically includes used classes
3. For development, the watcher will recompile automatically
4. No additional configuration needed

## Troubleshooting

If templates aren't found after upgrade:
- Check that view files include template compilation for all .html.eex files
- Run `mix compile` to trigger template compilation
- Verify file names match what the controller is trying to render

If assets aren't loading:
- Check that mix is running the esbuild and tailwind watchers
- Verify assets are in priv/static/assets/
- Check that templates reference /assets/ paths, not /js/ or /css/

If CSS isn't applying:
- Ensure @tailwind directives are at top of app.css
- Check that tailwind.config.js content paths include your templates
- Rebuild: `mix assets.deploy` or restart watchers

═══════════════════════════════════════════════════════════════════════════════

For detailed explanations, see:
- PHOENIX_UPGRADE.md - Technical deep dive
- GITHUB_AUTH_FIX.md - OAuth configuration details
- UPGRADE_SUMMARY.md - Quick reference

