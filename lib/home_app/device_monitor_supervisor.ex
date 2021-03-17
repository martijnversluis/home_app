defmodule HomeApp.DeviceMonitorSupervisor do
  alias HomeApp.{Configuration, ConfigurationAgent, DeviceDriver}

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def start_link() do
    Supervisor.start_link(children(), name: __MODULE__, strategy: :one_for_one)
  end

  defp children() do
    ConfigurationAgent.get_configuration()
    |> Configuration.get_interfaces_with_devices()
    |> Enum.reduce([], fn {%{type: interface_type} = interface, devices}, acc ->
      driver = DeviceDriver.get_driver!(interface_type)

      acc ++ [
        {
          HomeApp.DeviceMonitor,
          {driver, interface, devices}
        },
        {
          driver,
          {interface}
        }
      ]
    end)
    |> IO.inspect(label: "monitor children")
  end
end
