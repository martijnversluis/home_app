defmodule Hue.Driver do
  alias Hue.Client
  use GenServer

  def start_link({interface}) do
    GenServer.start_link(__MODULE__, {interface}, name: name(interface))
  end

  def init({%{host: host, port: port} = _interface}) do
    {:ok, client} = Client.start_link(host, port)
    {:ok, client}
  end

  defp name(%{interface: id, interface_type: type} = _device_info), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")
  defp name(%{id: id, type: type} = _interface), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

  def activate(device_info), do: GenServer.call(name(device_info), {:activate, device_info})
  def deactivate(device_info), do: GenServer.call(name(device_info), {:deactivate, device_info})
  def get_value(device_info), do: GenServer.call(name(device_info), {:get_value, device_info})
  def change(device_info, %{} = parameters), do: GenServer.call(name(device_info), {:change, device_info, parameters})

  def handle_call(
        {
          :deactivate,
          %{host: host, pin: pin, config: %{username: username}, connection: connection} = _device
        },
        _,
        client
      ) when connection in ["hue_dimmable_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(pin, %{on: false})

    {:reply, {:ok, result}, client}
  end

  def handle_call(
        {
          :activate,
          %{host: host, pin: pin, config: %{username: username}, connection: connection} = _device
        },
        _,
        client
      ) when connection in ["hue_dimmable_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(pin, %{on: true})

    {:reply, {:ok, result}, client}
  end

  def handle_call(
        {
          :get_value,
          %{host: host, pin: pin, config: %{username: username}, connection: connection} = _device
        },
        _,
        client
      ) when connection in ["hue_dimmable_light", "hue_go"] do
    state =
      login(host, username)
      |> Client.get_light(pin)
      |> Map.fetch!(:state)

    {
      :reply,
      {:ok, %{"on" => state.on, "brightness" => state.brightness}},
      client
    }
  end

  def handle_call(
        {
          :get_value,
          %{host: host, pin: pin, config: %{username: username}, connection: "hue_outlet"} = _device
        },
        _,
        client
      ) do
    %{state: %{on: on}} =
      login(host, username)
      |> Client.get_light(pin)

    {:reply, {:ok, %{"on" => on}}, client}
  end

  def handle_call(
        {
          :get_value,
          %{host: host, pin: pin, config: %{username: username}, connection: "hue_daylight_sensor"} = _device
        },
        _,
        client
      ) do
    %{state: %{daylight: daylight}} =
      login(host, username)
      |> Client.get_sensor(pin)

    {:reply, {:ok, %{"on" => daylight}}, client}
  end

  def handle_call(
        {
          :change,
          %{host: host, pin: pin, config: %{username: username}, connection: connection} = _device,
          %{} = parameters
        },
        _,
        client
      ) when connection in ["hue_dimmable_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(pin, atomize_keys(parameters))

    {:reply, {:ok, result}, client}
  end

  defp atomize_keys(%{} = map) do
    map
    |> Enum.map(fn {key, value} -> {String.to_existing_atom("#{key}"), value} end)
    |> Map.new()
  end

  defp login(host, username) do
    Client.login(host, EEx.eval_string(username))
  end
end
