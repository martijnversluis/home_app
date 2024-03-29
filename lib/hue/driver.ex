defmodule Hue.Driver do
  alias Hue.Client
  use HomeApp.DeviceDriver

  def init({%{host: host, port: port} = _interface}) do
    {:ok, client} = Client.start_link(host, port)
    {:ok, client}
  end

  def activate(device_info), do: GenServer.call(name(device_info), {:activate, device_info})
  def deactivate(device_info), do: GenServer.call(name(device_info), {:deactivate, device_info})
  def blink(device_info), do: GenServer.call(name(device_info), {:blink, device_info})

  def change(device_info, %{} = parameters),
    do: GenServer.call(name(device_info), {:change, device_info, parameters})

  def handle_call(
        {
          :deactivate,
          %{
            host: host,
            config: %{id: id, username: username},
            device_type: %{id: device_type_id}
          } = _device
        },
        _,
        client
      )
      when device_type_id in ["hue_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(id, %{on: false})

    {:reply, {:ok, result}, client}
  end

  def handle_call(
        {
          :activate,
          %{
            host: host,
            config: %{id: id, username: username},
            device_type: %{id: device_type_id}
          } = _device
        },
        _,
        client
      )
      when device_type_id in ["hue_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(id, %{on: true})

    {:reply, {:ok, result}, client}
  end

  def handle_call(
        {
          :blink,
          %{
            host: host,
            config: %{id: id, username: username},
            device_type: %{id: device_type_id}
          } = _device
        },
        _,
        client
      )
      when device_type_id in ["hue_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(id, %{alert: "lselect"})

    {:reply, {:ok, result}, client}
  end

  def handle_call(
        {
          :change,
          %{
            host: host,
            config: %{id: id, username: username},
            device_type: %{id: device_type_id}
          } = _device,
          %{} = parameters
        },
        _,
        client
      )
      when device_type_id in ["hue_light", "hue_go", "hue_outlet"] do
    result =
      login(host, username)
      |> Client.update_light(
        id,
        parameters
        |> atomize_keys()
        |> convert_brightness()
      )

    {:reply, {:ok, result}, client}
  end

  defp convert_brightness(%{brightness: brightness} = parameters) when is_binary(brightness) do
    parameters
    |> Map.put(:brightness, String.to_integer(brightness))
    |> convert_brightness()
  end

  defp convert_brightness(%{brightness: brightness} = parameters) when is_number(brightness) do
    Map.put(parameters, :brightness, brightness * 2.55)
  end

  defp convert_brightness(%{} = parameters), do: parameters

  defp get_device_value(interface, device_infos, state) when is_list(device_infos) do
    Map.new(device_infos, fn %{id: id} = device_info ->
      {id, get_device_value(interface, device_info, state)}
    end)
  end

  defp get_device_value(
         _interface,
         %{
           host: host,
           config: %{id: id, username: username},
           device_type: %{id: device_type_id}
         } = _device_info,
         _state
       )
       when device_type_id in ["hue_light", "hue_go"] do
    %{state: %{"on" => on, "bri" => brightness}} =
      login(host, username)
      |> Client.get_light(id)

    {:ok, %{"on" => on, "brightness" => Float.ceil(brightness / 2.55)}}
  end

  defp get_device_value(
         _interface,
         %{
           host: host,
           config: %{id: id, username: username},
           device_type: %{id: "hue_outlet"}
         } = _device_info,
         _state
       ) do
    %{state: %{"on" => on}} =
      login(host, username)
      |> Client.get_light(id)

    {:ok, %{"on" => on}}
  end

  defp get_device_value(
         _interface,
         %{
           host: host,
           config: %{id: id, username: username},
           device_type: %{id: "hue_daylight_sensor"}
         } = _device_info,
         _state
       ) do
    %{state: %{"daylight" => daylight}} =
      login(host, username)
      |> Client.get_sensor(id)

    {:ok, %{"on" => daylight}}
  end

  defp get_device_value(
         _interface,
         %{
           host: host,
           config: %{id: id, username: username},
           device_type: %{id: "hue_dimmer_switch"}
         } = _device_info,
         _state
       ) do
    %{
      state: %{"buttonevent" => button_event},
      config: %{"battery" => battery_level},
      capabilities: %{"inputs" => inputs}
    } =
      login(host, username)
      |> Client.get_sensor(id)

    {
      :ok,
      %{"button_event" => button_event, "battery_level" => battery_level}
      |> Map.merge(get_button_event_info(button_event, inputs))
    }
  end

  defp atomize_keys(%{} = map) do
    map
    |> Enum.map(fn {key, value} -> {String.to_existing_atom("#{key}"), value} end)
    |> Map.new()
  end

  defp login(host, username) do
    Client.login(host, username)
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
            "event" => event["eventtype"],
            "description" =>
              "Button #{button_index} #{event["eventtype"] |> String.replace("_", " ")}"
          }
        )
      end)
    end)
    |> Map.fetch!(button_event)
  end
end
