# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :discuss,
  ecto_repos: [Discuss.Repo]

# Configures the endpoint
config :discuss, Discuss.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "r3IRW+Dt1PQePAoDle3oy9mLC4bWfu5Tc+3sTxxHcDzzu8LfNYSePe8jWjG2qv6z",
  render_errors: [view: Discuss.ErrorView, accepts: ~w(html json)],
  pubsub_server: Discuss.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure Phoenix's JSON encoder
config :phoenix, :json_library, Jason

# Configure esbuild
config :esbuild,
  version: "0.20.0",
  default: [
    args: ~w(priv/static/js/app.js --bundle --target=es2017 --outdir=priv/static/assets),
    cd: Path.expand("../", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind
config :tailwind,
  version: "3.4.0",
  default: [
    args: ~w(--input=priv/static/css/app.css --output=priv/static/assets/app.css),
    cd: Path.expand("../", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :ueberauth, Ueberauth,
  providers: [
    github: { Ueberauth.Strategy.Github, [send_redirect_uri: false, scope: "user:email"] }
  ]
