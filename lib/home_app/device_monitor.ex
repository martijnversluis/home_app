defmodule HomeApp.DeviceMonitor do
  alias HomeApp.{DeviceControl, Event}
  use GenServer

  def child_spec({driver, %{id: interface_id, type: interface_type} = interface, devices}) do
    %{
      id: String.to_atom("#{__MODULE__}_#{interface_type}_#{interface_id}"),
      start: {__MODULE__, :start_link, [{driver, interface, devices}]}
    }
  end

  def start_link({driver, interface, devices}) do
    GenServer.start_link(__MODULE__, {driver, interface, devices}, name: name(interface))
  end

  defp name(%{id: id, type: type} = _interface), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

  def init({driver, %{polling_interval: polling_interval} = interface, devices}) do
    IO.inspect(driver, label: "init device monitor")
    process = name(interface)
    send(process, :update)
    :timer.send_interval(polling_interval, process, :update)
    {:ok, {driver, interface, devices}}
  end

  def update(pid) do
    GenServer.call(pid, :update)
  end

  def handle_info(:update, {driver, %{type: interface_type} = interface, devices} = state) do
    for {device_id, response} <-
          DeviceControl.get_value(interface, devices)
          |> IO.inspect(label: "device state for #{interface_type}") do
      case response do
        {:ok, value} ->
          Event.broadcast(
            HomeApp.PubSub,
            Event.new("device:state_reported", device_id, value)
          )

        {:error, description} ->
          IO.puts("Error getting value for #{device_id}")
      end
    end

    {:noreply, state}
  end
end
