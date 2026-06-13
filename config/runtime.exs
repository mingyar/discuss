import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/discuss start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :discuss, DiscussWeb.Endpoint, server: true
end

if System.get_env("FLY_APP_NAME") do
  config :discuss, DiscussWeb.Endpoint, server: true
end

config :discuss, DiscussWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  # On Fly.io, resolve the database hostname via the OS resolver (getent)
  # to bypass Erlang's DNS resolver. The getent command calls glibc's
  # getaddrinfo(), which queries Fly.io's DNS at fdaa::3 and returns the
  # real IPv4 A records. We substitute the resolved IP into the DATABASE_URL
  # so Erlang never needs to resolve the hostname — it just connects to the
  # IP directly via the default (IPv4) socket.
  #
  # Because we replace the hostname with a raw IPv4 address, SSL certificate
  # hostname verification would fail (Neon's cert is for *.c-2.us-east-1.aws.neon.tech,
  # not the IP). To fix this, we pass the original hostname as server_name_indication
  # in ssl_opts, which tells Erlang's SSL to use that hostname for SNI and for
  # certificate hostname verification.
  {database_url, ssl_opts_extra} =
    if System.get_env("FLY_APP_NAME") do
      uri = URI.parse(database_url)

      if uri.host && System.find_executable("getent") do
        case System.cmd("getent", ["hosts", uri.host], stderr_to_stdout: true) do
          {result, 0} ->
            ip =
              result
              |> String.split(" ", trim: true)
              |> List.first()

            if ip && ip != uri.host do
              {String.replace(database_url, uri.host, ip),
               [server_name_indication: to_charlist(uri.host)]}
            else
              {database_url, []}
            end

          _ ->
            {database_url, []}
        end
      else
        {database_url, []}
      end
    else
      {database_url, []}
    end

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # Build the ssl config for the Repo.
  # Postgrex 0.22.0 deprecated `ssl_opts:` in favor of passing opts directly
  # inside the `ssl:` keyword list. The keyword list form merges user opts on
  # top of Postgrex's secure defaults (verify_peer + customize_hostname_check).
  ssl_config =
    cond do
      System.get_env("FLY_APP_NAME") && ssl_opts_extra != [] ->
        # On Fly.io with getent IP substitution: need to provide cacerts
        # (for peer verification) plus custom server_name_indication for
        # proper SNI and hostname check against the Neon wildcard cert.
        [cacerts: :public_key.cacerts_get()] ++ ssl_opts_extra

      System.get_env("FLY_APP_NAME") ->
        true

      true ->
        false
    end

  config :discuss, Discuss.Repo,
    ssl: ssl_config,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :discuss, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  if System.get_env("FLY_APP_NAME") do
    config :discuss, :dns_cluster_query, "#{System.get_env("FLY_APP_NAME")}.internal"
  end

  config :discuss, DiscussWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :discuss, DiscussWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :discuss, DiscussWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :discuss, Discuss.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
