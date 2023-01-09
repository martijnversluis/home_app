defmodule MqttIO.Driver do
  use HomeApp.DeviceDriver, monitor_with: MqttIO.Monitor

  def init({interface}), do: {:ok, {interface}}

  def device_state_changed(interface, device, payload) do
    GenServer.call(name(interface), {:device_state_changed, device, payload})
  end

  def handle_call({:device_state_changed, %{id: id} = device, payload}, _, state) do
    HomeApp.DeviceStateAgent.set_device_state(id, device_value(device, payload))
    {:noreply, state}
  end

  defp device_value(%{type: "mqtt_io_digital_input"} = _device, "ON" = _value),
    do: %{"on" => true}

  defp device_value(%{type: "mqtt_io_digital_input"} = _device, "OFF" = _value),
    do: %{"on" => false}

  defp device_value(%{} = device, value) do
    IO.inspect({device, value}, label: "unrecognized value")
  end
end
