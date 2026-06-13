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

  pipeline :require_auth do
    plug DiscussWeb.Plugs.RequireAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DiscussWeb do
    pipe_through :browser

    live "/", TopicLive.Index, :index
    live "/topics", TopicLive.Index, :index
    live "/topics/new", TopicLive.Index, :new
    live "/topics/:id/edit", TopicLive.Index, :edit
    live "/topics/:id/show/edit", TopicLive.Show, :edit
    live "/topics/:id", TopicLive.Show, :show
  end

  scope "/auth", DiscussWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/signout", AuthController, :signout
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
