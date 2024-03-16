defmodule AccumulatorWeb.Router do
  use AccumulatorWeb, :router

  import AccumulatorWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AccumulatorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AccumulatorWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/redirect", PageController, :redirect
    live "/dashboard", DashboardLive
    live "/spotify", SpotifyLive
    delete "/logout", UserSessionController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", AccumulatorWeb do
  #   pipe_through :api
  # end

  if Application.compile_env(:accumulator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AccumulatorWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{AccumulatorWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/login", UserLoginLive, :new
    end

    post "/login", UserSessionController, :create
  end

  scope "/", AccumulatorWeb do
    # pipe_through [:browser, :require_authenticated_user]
    pipe_through [:browser]

    live_dashboard "/livedashboard", metrics: AccumulatorWeb.Telemetry

    live "/bin", BinLive.Home
    live "/bin/create", BinLive.Create
    live "/bin/:id/show", BinLive.Show
    live "/bin/:id/edit", BinLive.Edit

    live "/sessions", SessionsLive
  end
end
