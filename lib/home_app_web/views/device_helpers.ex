defmodule HomeAppWeb.DeviceHelpers do
  alias HomeApp.Configuration
  import Phoenix.HTML.Tag

  def device_control(
        %{id: device_id} = device,
        %{
          id: characteristic_id,
          type: "numeric",
          writable: true,
          range: %{min: min, max: max}
        } = characteristic,
        value
      ) do
    tag(
      :input,
      class: "device__slider",
      id: "#{device_id}_#{characteristic_id}",
      max: max,
      min: min,
      name: "#{device_id}_#{characteristic_id}",
      type: "range",
      value: value,
      "phx-value-device-id": device_id,
      "phx-value-characteristic": characteristic_id,
      "phx-hook": "NumericSlider",
      "phx-click": ""
    )
  end

  def device_control(_device, %{} = _characteristic, _value), do: nil

  def devices_by_room(
        %{devices: devices} = configuration,
        %{} = values
      ) do
    devices
    |> Enum.group_by(fn device -> device.room end)
    |> Enum.map(fn {room_id, devices} ->
      {
        Configuration.get_room(configuration, room_id),
        devices
        |> Enum.map(fn device ->
          device_info(device, configuration, Map.fetch!(values, device.id))
        end)
        |> Enum.sort_by(fn %{} = device_info -> device_info.characteristic end)
      }
    end)
    |> Enum.sort_by(fn {room, _devices} -> room.name end)
  end

  defp device_info(%{id: device_id} = device, %{} = configuration, value) do
    %{
      device_type: %{icon: icon},
      characteristics: characteristics
    } = Configuration.get_device_info(configuration, device_id)

    %{
      icon: icon,
      characteristic: characteristic_id(characteristics),
      state: state(device, characteristics, value),
      label: label(device, characteristics, value),
      style: style(device, characteristics, value),
      click_action: click_action(characteristics, value),
      button_icon: button_icon(characteristics, value),
      characteristics: characteristics
    }
    |> Map.merge(device)
  end

  defp characteristic_id(characteristics) when is_list(characteristics) do
    characteristics |> List.first() |> characteristic_id()
  end

  defp characteristic_id(%{id: id} = _characteristic), do: id

  defp button_icon(characteristics, value) when is_list(characteristics) do
    Enum.find_value(characteristics, fn characteristic ->
      button_icon(characteristic, get_value(value, characteristic))
    end)
  end

  defp button_icon(%{type: "binary", writable: true}, true = _value), do: "toggle-on"
  defp button_icon(%{type: "binary", writable: true}, false = _value), do: "toggle-off"
  defp button_icon(%{} = _characteristic, _value), do: nil

  defp click_action(_characteristics, nil = _value), do: nil

  defp click_action(characteristics, value) when is_list(characteristics) do
    Enum.find_value(characteristics, fn characteristic ->
      click_action(characteristic, get_value(value, characteristic))
    end)
  end

  defp click_action(%{type: "binary", writable: true}, true = _value), do: "deactivate"
  defp click_action(%{type: "binary", writable: true}, false = _value), do: "activate"
  defp click_action(%{writable: false}, _value), do: nil

  defp label(device, characteristics, value) when is_list(characteristics) do
    characteristic = List.first(characteristics)
    label(device, characteristic, get_value(value, characteristic))
  end

  defp label(%{name: device_name} = _device, %{type: "binary"} = _characteristic, _value), do: device_name

  defp label(%{} = _device, %{type: "numeric"} = _characteristic, nil = _value), do: "-"

  defp label(%{} = _device, %{type: "numeric", unit: unit, decimals: decimals} = _characteristic, value) do
    "#{round_numeric_value(value, decimals)} #{unit}"
  end

  defp label(%{} = _device, %{type: "timestamp"} = _characteristic, value) do
    "#{value}"
    |> Timex.parse!("{s-epoch}")
    |> Timex.format!("{relative}", :relative)
  end

  defp round_numeric_value(value, nil), do: value
  defp round_numeric_value(value, decimals) when is_integer(decimals), do: Float.ceil(value, decimals)

  defp state(device, characteristics, value) when is_list(characteristics) do
    characteristic = List.first(characteristics)
    state(device, characteristic, get_value(value, characteristic))
  end

  defp state(%{} = _device, %{} = _characteristic, nil = _value), do: "unknown"

  defp state(
        %{} = _device,
        %{type: "binary", states: %{on: on_state, off: off_state}} = _characteristic,
        value
      ) do
    case value |> binary_state() do
      true -> on_state
      false -> off_state
    end
  end

  defp state(%{} = _device, %{type: "numeric", range: %{min: _min, max: _max}} = characteristic, value) do
    case numeric_to_scale(characteristic, value) do
      p when p < 0.3334 -> "low"
      p when p >= 0.6667 -> "high"
      _ -> "medium"
    end
  end

  defp state(%{} = _device, %{} = _characteristic, _value), do: "neutral"

  defp binary_state(true), do: true
  defp binary_state(false), do: false
  defp binary_state(0.0), do: false
  defp binary_state(0), do: false
  defp binary_state(1.0), do: true
  defp binary_state(1), do: true

  defp binary_state(float) when is_float(float) do
    round(float) |> binary_state()
  end

  defp style(device, characteristics, value) when is_list(characteristics) do
    characteristic = List.first(characteristics)
    style(device, characteristic, get_value(value, characteristic))
  end

#  defp style(%{} = _device, %{type: "numeric"} = characteristic, value) do
#    scale = numeric_to_scale(characteristic, value)
#    min_hue = 0
#    max_hue = 220
#    hue = max_hue - (scale * (max_hue - min_hue)) |> limit_number(min_hue, max_hue)
#    "--value-color: hsl(#{hue}deg 71% 53%)"
#  end

  defp style(%{} = _device, %{} = _characteristic, _value), do: ""

  defp numeric_to_scale(%{type: "numeric", range: %{min: min, max: max}} = _characteristic, value) do
    value / (max - min)
  end

  defp limit_number(number, min, max) do
    case number do
      n when n < min -> min
      n when n > max -> max
      _ -> number
    end
  end

  defp get_value(nil = value, _characteristic), do: nil
  defp get_value(%{} = value, %{source: source} = _characteristic), do: Map.fetch!(value, source)
end
