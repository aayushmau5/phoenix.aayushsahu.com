import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :accumulator, AccumulatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "4PNl6FixlYBOiZAYTU10Jm7643oVRuCID7Ot5JWCGJ4XIGbZoYovqeLYvtq4y93c",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :redix,
  config: [
    name: :redix,
    host: "localhost",
    port: 6379,
    socket_opts: [:inet6]
  ]
