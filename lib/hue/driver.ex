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

  defp name(%{interface: id, interface_type: type} = _device_info),
    do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

  defp name(%{id: id, type: type} = _interface), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

  def activate(device_info), do: GenServer.call(name(device_info), {:activate, device_info})
  def deactivate(device_info), do: GenServer.call(name(device_info), {:deactivate, device_info})
  def blink(device_info), do: GenServer.call(name(device_info), {:blink, device_info})
  def get_value(device_info), do: GenServer.call(name(device_info), {:get_value, device_info})

  def change(device_info, %{} = parameters),
    do: GenServer.call(name(device_info), {:change, device_info, parameters})

  def handle_call(
        {
          :deactivate,
          %{host: host, pin: pin, config: %{username: username}, connection: connection} = _device
        },
        _,
        client
      )
      when connection in ["hue_dimmable_light", "hue_go", "hue_outlet"] do
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
      )
      when connection in ["hue_dimmable_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(pin, %{on: true})

    {:reply, {:ok, result}, client}
  end

  def handle_call(
        {
          :blink,
          %{host: host, pin: pin, config: %{username: username}, connection: connection} = _device
        },
        _,
        client
      )
      when connection in ["hue_dimmable_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(pin, %{alert: "lselect"})

    {:reply, {:ok, result}, client}
  end

  def handle_call(
        {
          :get_value,
          %{host: host, pin: pin, config: %{username: username}, connection: connection} = _device
        },
        _,
        client
      )
      when connection in ["hue_dimmable_light", "hue_go"] do
    %{state: %{"on" => on, "bri" => brightness}} =
      login(host, username)
      |> Client.get_light(pin)

    {
      :reply,
      {:ok, %{"on" => on, "brightness" => brightness}},
      client
    }
  end

  def handle_call(
        {
          :get_value,
          %{host: host, pin: pin, config: %{username: username}, connection: "hue_outlet"} =
            _device
        },
        _,
        client
      ) do
    %{state: %{"on" => on}} =
      login(host, username)
      |> Client.get_light(pin)

    {
      :reply,
      {:ok, %{"on" => on}},
      client
    }
  end

  def handle_call(
        {
          :get_value,
          %{
            host: host,
            pin: pin,
            config: %{username: username},
            connection: "hue_daylight_sensor"
          } = _device
        },
        _,
        client
      ) do
    %{state: %{"daylight" => daylight}} =
      login(host, username)
      |> Client.get_sensor(pin)

    {
      :reply,
      {:ok, %{"on" => daylight}},
      client
    }
  end

  def handle_call(
        {
          :get_value,
          %{host: host, pin: pin, config: %{username: username}, connection: "hue_dimmer_switch"} =
            _device
        },
        _,
        client
      ) do
    %{
      state: %{"buttonevent" => button_event},
      config: %{"battery" => battery_level},
      capabilities: %{"inputs" => inputs}
    } =
      login(host, username)
      |> Client.get_sensor(pin)

    {
      :reply,
      {
        :ok,
        %{"button_event" => button_event, "battery_level" => battery_level}
        |> Map.merge(get_button_event_info(button_event, inputs))
      },
      client
    }
  end

  def handle_call(
        {
          :change,
          %{host: host, pin: pin, config: %{username: username}, connection: connection} =
            _device,
          %{} = parameters
        },
        _,
        client
      )
      when connection in ["hue_dimmable_light", "hue_go", "hue_outlet"] do
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

  defp get_button_event_info(button_event, inputs) do
    inputs
    |> Stream.with_index(1)
    |> Enum.reduce(%{}, fn {%{"events" => events}, button_index}, acc ->
      Enum.reduce(events, acc, fn event, acc2 ->
        Map.put(
          acc2,
          event["buttonevent"],
          %{
            "button" => button_index,
            "event_type" => event["eventtype"],
            "description" =>
              "Button #{button_index} #{event["eventtype"] |> String.replace("_", " ")}"
          }
        )
      end)
    end)
    |> Map.fetch!(button_event)
  end
end
