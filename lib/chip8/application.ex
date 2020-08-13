defmodule Chip8.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Chip8.Repo,
      # Start the Telemetry supervisor
      Chip8Web.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Chip8.PubSub},
      # Start the Endpoint (http/https)
      Chip8Web.Endpoint
      # Start a worker by calling: Chip8.Worker.start_link(arg)
      # {Chip8.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chip8.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Chip8Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
