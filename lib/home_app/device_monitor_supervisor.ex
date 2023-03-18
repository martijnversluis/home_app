defmodule HomeApp.DeviceMonitorSupervisor do
  alias HomeApp.{Configuration, ConfigurationAgent, DeviceControl}

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
      driver = DeviceControl.get_driver!(interface_type)
      acc ++ monitor_config(driver, interface, devices) ++ driver_config(driver, interface)
    end)
  end

  defp monitor_config(driver, interface, devices) do
    [
      {
        driver.monitor_module() || HomeApp.DeviceMonitor,
        {driver, interface, devices}
      }
    ]
  end

  defp driver_config(driver, interface) do
    [
      Supervisor.child_spec(
        {driver, {interface}},
        id: driver.name(interface)
      )
    ]
  end
end
