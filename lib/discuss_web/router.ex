defmodule DiscussWeb.Router do
  use DiscussWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DiscussWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug DiscussWeb.Plugs.SetUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  live_session :topics, on_mount: [{DiscussWeb.UserAuth, :default}] do
    scope "/", DiscussWeb do
      pipe_through :browser

      live "/", TopicLive.Index, :index
      live "/topics", TopicLive.Index, :index
      live "/topics/new", TopicLive.Index, :new
      live "/topics/:id", TopicLive.Show, :show
    end
  end

  scope "/health", DiscussWeb do
    get "/liveness", HealthController, :liveness
    get "/readiness", HealthController, :readiness
  end

  scope "/auth", DiscussWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/signout", AuthController, :signout
  end

  # Other scopes may use custom stacks.
  # scope "/api", DiscussWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:discuss, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DiscussWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
