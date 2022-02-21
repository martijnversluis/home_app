defmodule HomeApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Dotenv.load()
    Mix.Task.run("loadconfig")

    children = [
      HomeAppWeb.Telemetry,
      {Phoenix.PubSub, name: HomeApp.PubSub},
      HomeAppWeb.Endpoint,
      HomeApp.ConfigurationAgent,
      HomeApp.DeviceMonitorSupervisor,
      HomeApp.DeviceStateAgent,
      HomeApp.EventMonitor,
      {HomeApp.Clock, {HomeApp.PubSub, "clock:tick"}}
      HomeApp.DeviceHoldMonitor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HomeApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HomeAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
