defmodule MqttIO.Monitor do
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

  def init({
        driver,
        %{
          config: %{
            topic: topic
          }
        } = interface,
        devices
      }) do
    {:ok, pid} =
      opts(interface)
      |> IO.inspect(label: "MQTT options")
      |> :emqtt.start_link()

    {:ok, _} = :emqtt.connect(pid)
    {:ok, _, _} = :emqtt.subscribe(pid, topic)
    {:ok, {pid, driver, interface, devices}}
  end

  def handle_info(
        {
          :publish,
          %{topic: "home/input/" <> device_id, payload: payload} = _data
        },
        {_pid, driver, interface, devices} = state
      ) do
    case Enum.find(devices, fn device -> device.id == device_id end) do
      %{} = device ->
        driver.device_state_changed(interface, device, payload)

      _ ->
        IO.inspect({device_id, payload, state}, label: "ignored mqtt message")
    end

    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.inspect(message, label: "Ignoring MQTT message")
    {:noreply, state}
  end

  defp opts(%{host: host, port: port} = interface) do
    {:ok, hostname} = :inet.gethostname()

    %{
      host: normalize_host(host),
      port: port,
      clientid: "homeapp_#{hostname}_#{name(interface)}",
      clean_start: false,
      name: :emqtt
    }
  end

  defp normalize_host(host) when is_binary(host), do: String.to_charlist(host)
  defp normalize_host(host) when is_list(host), do: host

  defp name(%{id: id, type: type} = _interface), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")
end
