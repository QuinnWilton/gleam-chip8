defmodule Chip8.Repo do
  use Ecto.Repo,
    otp_app: :chip8,
    adapter: Ecto.Adapters.Postgres
end
