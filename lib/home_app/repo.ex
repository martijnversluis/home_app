defmodule HomeApp.Repo do
  use Ecto.Repo,
    otp_app: :home_app,
    adapter: Ecto.Adapters.Postgres
end
