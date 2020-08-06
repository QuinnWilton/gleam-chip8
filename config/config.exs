# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :chip8,
  ecto_repos: [Chip8.Repo]

# Configures the endpoint
config :chip8, Chip8Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ceULQBPCbd1SjeW/Akx6ZSvPjfrXum4gP7uNOGhmLuFlfBBklet7pqsyscblT8KL",
  render_errors: [view: Chip8Web.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Chip8.PubSub,
  live_view: [signing_salt: "peQbyUU0"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
