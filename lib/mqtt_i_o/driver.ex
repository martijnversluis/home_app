defmodule MqttIO.Driver do
  use HomeApp.DeviceDriver, monitor_with: MqttIO.Monitor
  use Tortoise.Handler

  def init([interface, devices]), do: init({interface, devices})
  def init({interface, devices}), do: {:ok, {interface, devices}}

  def connection(status, state) do
    # `status` will be either `:up` or `:down`; you can use this to
    # inform the rest of your system if the connection is currently
    # open or closed; tortoise should be busy reconnecting if you get
    # a `:down`
    IO.puts("MQTT connection: #{status}")
    IO.inspect(state, label: "MqttIO driver state")
    {:ok, state}
  end

  def handle_message(["home", "input", device_id] = topic, payload, {_interface, devices} = state) do
    case Enum.find(devices, fn device -> device.id == device_id end) do
      %{} = device ->
        HomeApp.DeviceStateAgent.set_device_state(device_id, device_value(device, payload))
      _ -> IO.inspect({topic, payload, state}, label: "ignored mqtt message")
    end

    {:ok, state}
  end

  def handle_message(topic, payload, state) do
    IO.inspect({topic, payload, state}, label: "ignored mqtt message")
    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    {:ok, state}
  end

  def terminate(reason, state) do
    # tortoise doesn't care about what you return from terminate/2,
    # that is in alignment with other behaviours that implement a
    # terminate-callback
    :ok
  end

  defp device_value(%{type: "mqtt_io_digital_input"} = _device, "ON" = _value), do: %{"on" => true}
  defp device_value(%{type: "mqtt_io_digital_input"} = _device, "OFF" = _value), do: %{"on" => false}

  defp device_value(%{} = device, value) do
    IO.inspect({device, value}, label: "unrecognized value")
  end
end
