# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# config :home_app, ecto_repos: [HomeApp.Repo]

config :home_app, :yml_config, "config/config.yml"

config :home_app, :device_drivers,
  devantech_eth: DevantechETH.Driver,
  hue: Hue.Driver,
  mqtt_io: MqttIO.Driver,
  smoov: Smoov.Driver,
  network_discovery: NetworkDiscovery.Driver

config :home_app, :notifiers, http: HTTPNotifier

# Configures the endpoint
config :home_app, HomeAppWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "TEkoOPhdsdqkfk0c5dAZbZOW9+D2YZml8q4JsuMMFTcXb3D7+ks2ehNQqIF7kxuY",
  render_errors: [view: HomeAppWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HomeApp.PubSub,
  live_view: [signing_salt: "wWzw4KpL"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
