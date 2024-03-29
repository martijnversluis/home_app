defmodule MqttIO.Monitor do
  use GenServer
  alias HomeApp.Event
  @topic "home/input/"

  def child_spec() do
    %{
      id: String.to_atom("#{__MODULE__}"),
      start: {__MODULE__, :start_link, []}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init({_driver, %{config: %{topic: topic}, host: _host, port: _port} = interface, devices}) do
    {:ok, pid} = opts(interface) |> :emqtt.start_link()
    {:ok, _} = :emqtt.connect(pid)
    {:ok, _, _} = :emqtt.subscribe(pid, "#{topic}")
    {:ok, {HomeApp.PubSub, pid, devices}}
  end

  def handle_info(
        {
          :publish,
          %{topic: @topic <> device_id, payload: payload} = _data
        },
        {_pub_sub, _pid, _devices} = state
      ) do
    IO.inspect({device_id, payload, state}, label: "mqtt message")

    Event.broadcast(
      HomeApp.PubSub,
      Event.new("device:state_reported", device_id, %{on: payload == "ON"})
    )

    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.inspect(message, label: "Ignoring MQTT message")
    {:noreply, state}
  end

  defp opts(%{host: host, port: port} = _interface) do
    {:ok, hostname} = :inet.gethostname()

    %{
      host: normalize_host(host),
      port: port,
      clientid: "homeapp_#{hostname}",
      clean_start: false,
      name: :emqtt
    }
  end

  defp normalize_host(host) when is_binary(host), do: String.to_charlist(host)
  defp normalize_host(host) when is_list(host), do: host
end
