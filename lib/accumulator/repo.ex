defmodule Accumulator.Repo do
  use Ecto.Repo,
    otp_app: :accumulator,
    adapter: Ecto.Adapters.Postgres
end
