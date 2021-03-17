defmodule HomeApp.DeviceMonitor do
  alias HomeApp.{Configuration, ConfigurationAgent, DeviceStateAgent}
  use GenServer

  def start_link({driver, interface, devices}) do
    GenServer.start_link(__MODULE__, {driver, interface, devices}, name: name(interface))
  end

  defp name(%{id: id, type: type} = _interface), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

  def init({driver, %{polling_interval: polling_interval} = interface, devices}) do
    process = name(interface)
    send(process, :update)
    :timer.send_interval(polling_interval, process, :update)
    {:ok, {driver, interface, devices}}
  end

  def update(pid) do
    GenServer.call(pid, :update)
  end

  def handle_info(:update, {driver, interface, devices} = state) do
    for device <- devices, do: update_device(driver, device)
    {:noreply, state}
  end

  defp update_device(driver, %{id: device_id} = _device) do
    response =
      ConfigurationAgent.get_configuration()
      |> Configuration.get_device_info(device_id)
      |> driver.get_value()

    case response do
      {:ok, value} -> DeviceStateAgent.set_device_state(device_id, value)
      {:error, error} -> {:error, error}
    end
  end
end
