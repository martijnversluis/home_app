defmodule HomeAppWeb.PageLive do
  alias HomeApp.Configuration
  alias HomeApp.DeviceDriver
  use HomeAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    configuration = get_configuration()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(HomeApp.PubSub, "device:state_changed")
    end

    {
      :ok,
      assign(socket, %{
        configuration: configuration,
        values: get_values(configuration)
      })}
  end

  @impl true
  def handle_info({"device:state_changed", device_id, {_previous_state, new_state}}, socket) do
    {:noreply, assign(socket, :values, Map.put(socket.assigns.values, device_id, new_state))}
  end

  @impl true
  def handle_event(action, %{"device-id" => device_id}, socket) when action in ["activate", "deactivate"] do
    device_info = Configuration.get_device_info(get_configuration(), device_id)
    DeviceDriver.dispatch(device_info, action)

    case DeviceDriver.get_value(device_info) do
      {:ok, value} ->
        IO.inspect(value, label: "New value for #{device_id}")
        {
          :noreply,
          socket
          |> assign(%{values: Map.put(socket.assigns.values, device_id, value)})
        }
      {:error, error} ->
        IO.inspect(error, label: "Error reading value for \"#{device_id}}\"")
        {
          :noreply,
          socket
          |> put_flash(:error, "Could not read the value for \"#{device_id}\"")
        }
    end
  end

  defp get_configuration() do
    HomeApp.ConfigurationAgent.get_configuration()
  end

  defp get_values(%{devices: devices} = configuration) do
    for %{id: device_id} = _device <- devices, into: %{} do
      case Configuration.get_device_info(configuration, device_id) |> DeviceDriver.get_value() do
        {:ok, value} -> {device_id, value}
        {:error, _error} -> {device_id, nil}
      end
    end
  end
end
