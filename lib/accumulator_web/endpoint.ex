defmodule AccumulatorWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :accumulator

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_accumulator_key",
    signing_salt: "grMY6rNh",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :accumulator,
    gzip: false,
    only: AccumulatorWeb.static_paths()

  plug Plug.Static,
    at: "/uploads",
    from: Application.compile_env(:accumulator, :serve_dir),
    gzip: Mix.env() == :prod

  if Code.ensure_loaded?(Tidewave) do
    plug Tidewave
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug AccumulatorWeb.Router

  # A socket route
  socket "/socket", AccumulatorWeb.UserSocket,
    websocket: [
      connect_info: [session: @session_options],
      check_origin: {Accumulator.Origin, :my_check_origin?, []}
    ],
    longpoll: false

  socket "/tui", AccumulatorWeb.TUISocket,
    websocket: true,
    longpoll: false

  # socket "/extension", AccumulatorWeb.ExtensionSocket,
  #   websocket: true,
  #   longpoll: false
end
