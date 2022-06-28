defmodule Clubhouse.Repo do
  use Ecto.Repo,
    otp_app: :clubhouse,
    adapter: Ecto.Adapters.Postgres
end
