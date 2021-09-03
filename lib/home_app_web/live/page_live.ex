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
        values: get_values(configuration) |> IO.inspect(label: "values")
      })
    }
  end

  @impl true
  def handle_info({"device:state_changed", device_id, {_previous_state, new_state}}, socket) do
    {:noreply, assign(socket, :values, Map.put(socket.assigns.values, device_id, new_state))}
  end

  @impl true
  def handle_event(action, %{"device-id" => device_id}, socket)
      when action in ["activate", "deactivate"] do
    trigger_device_change(device_id, socket, fn device_info ->
      DeviceDriver.dispatch(device_info, action)
    end)
  end

  @impl true
  def handle_event(
        "device_change",
        %{
          "characteristic" => characteristic,
          "device_id" => device_id,
          "value" => value
        },
        socket
      ) do
    trigger_device_change(device_id, socket, fn device_info ->
      DeviceDriver.dispatch(device_info, "change", %{characteristic => value})
    end)
  end

  defp trigger_device_change(device_id, socket, fun) do
    device_info = Configuration.get_device_info(get_configuration(), device_id)
    fun.(device_info)
    reload_device_state(device_info, socket)
  end

  defp reload_device_state([device | other_devices], socket) do
    {:noreply, socket} = reload_device_state(device, socket)
    reload_device_state(other_devices, socket)
  end

  defp reload_device_state([] = _devices, socket), do: {:noreply, socket}

  defp reload_device_state(%{id: device_id} = device_info, socket) do
    case DeviceDriver.get_value(device_info) do
      {:ok, value} ->
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
