# GitHub OAuth Authentication Fix

## Problem
When attempting to sign up via GitHub, the application was throwing a `KeyError` because the email was not included in the GitHub OAuth response.

## Root Cause
The Ueberauth GitHub strategy wasn't configured to request the `user:email` scope, which is needed to retrieve the user's email from GitHub's OAuth endpoint.

## Solution
Updated the Ueberauth configuration to include the `user:email` scope and added defensive code in the controller to handle edge cases.

### Changes Made

#### 1. Configuration Update
**File: `config/config.exs`**

```elixir
# Before
config :ueberauth, Ueberauth,
  providers: [
    github: { Ueberauth.Strategy.Github, [send_redirect_uri: false] }
  ]

# After
config :ueberauth, Ueberauth,
  providers: [
    github: { Ueberauth.Strategy.Github, [send_redirect_uri: false, scope: "user:email"] }
  ]
```

#### 2. Controller Defensive Code
**File: `web/controllers/auth_controller.ex`**

```elixir
# Before
def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
  user_params = %{token: auth.credentials.token, email: auth.info.email, provider: "github"}
  changeset = User.changeset(%User{}, user_params)
  signin(conn, changeset)
end

# After
def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
  # GitHub may not return email in some cases, handle gracefully
  email = auth.info.email || auth.info.nickname || "user-#{auth.uid}@github.local"
  user_params = %{token: auth.credentials.token, email: email, provider: "github"}
  changeset = User.changeset(%User{}, user_params)
  signin(conn, changeset)
end
```

The fallback logic:
1. First tries to use the email from GitHub (`auth.info.email`)
2. Falls back to the GitHub username (`auth.info.nickname`)
3. As a last resort, generates a unique email based on the GitHub user ID

This ensures the application never crashes due to missing email.

## GitHub Scopes
The `user:email` scope allows your application to:
- Read user email addresses
- Access both public and private email addresses (based on user settings)

For more details on GitHub OAuth scopes, see: https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps

## Testing
To test the fix:
1. Start the server: `mix phx.server`
2. Click "Sign in with Github"
3. Authorize the application
4. You should be successfully authenticated

## Future Improvements
If you need additional GitHub user information, you can request more scopes:
```elixir
# Example: requesting additional scopes
github: { 
  Ueberauth.Strategy.Github, 
  [
    send_redirect_uri: false, 
    scope: "user:email public_repo gist"  # Multiple scopes separated by space
  ] 
}
```

Common scopes:
- `user:email` - Read user email addresses
- `repo` - Full control of private repositories
- `public_repo` - Access public repositories
- `gist` - Create gists
- `read:user` - Read user profile data
