import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.

# Configures Swoosh API Client
config :swoosh, :api_client, Accumulator.Finch
config :accumulator, Accumulator.Mailer, adapter: Resend.Swoosh.Adapter

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :accumulator, AccumulatorWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: [
    "https://aayushsahu.com",
    "https://phoenix-aayushsahu-com.fly.dev",
    "https://phoenix.aayushsahu.com/"
  ]

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

# File upload config
config :accumulator,
  serve_dir: "/data",
  upload_dir: "/data"
