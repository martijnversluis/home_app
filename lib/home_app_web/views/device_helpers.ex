defmodule HomeAppWeb.DeviceHelpers do
  alias HomeApp.Configuration

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

  defp device_info(%{} = device, %{} = configuration, value) do
    device_type = Configuration.get_device_type(configuration, device.type)
    characteristic = Configuration.get_characteristic(configuration, device_type.characteristic)

    %{
      icon: device_type.icon,
      characteristic: characteristic.id,
      state: state(device, characteristic, value),
      label: label(device, characteristic, value),
      style: style(device, characteristic, value),
      click_action: click_action(characteristic, value),
      button_icon: button_icon(characteristic, value)
    }
    |> Map.merge(device)
  end

  defp button_icon(%{type: "binary", writable: true}, true = _value), do: "toggle-on"
  defp button_icon(%{type: "binary", writable: true}, false = _value), do: "toggle-off"
  defp button_icon(%{} = _characteristic, _value), do: nil

  defp click_action(%{type: "binary", writable: true}, true = _value), do: "deactivate"
  defp click_action(%{type: "binary", writable: true}, false = _value), do: "activate"
  defp click_action(%{writable: false}, _value), do: nil

  defp label(%{name: device_name} = _device, %{type: "binary"} = _characteristic, _value), do: device_name

  defp label(%{} = _device, %{type: "numeric", unit: unit, decimals: decimals} = _characteristic, value) do
    "#{round_numeric_value(value, decimals)} #{unit}"
  end

  defp round_numeric_value(value, nil), do: value
  defp round_numeric_value(value, decimals) when is_integer(decimals), do: Float.ceil(value, decimals)

  defp label(%{} = _device, %{type: "timestamp"} = _characteristic, value) do
    "#{value}"
    |> Timex.parse!("{s-epoch}")
    |> Timex.format!("{relative}", :relative)
  end

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

  defp binary_state(true), do: true
  defp binary_state(false), do: false
  defp binary_state(0.0), do: false
  defp binary_state(0), do: false
  defp binary_state(1.0), do: true
  defp binary_state(1), do: true

  defp binary_state(float) when is_float(float) do
    round(float) |> binary_state()
  end

  defp state(%{} = _device, %{type: "numeric", range: %{min: _min, max: _max}} = characteristic, value) do
    case numeric_to_scale(characteristic, value) do
      p when p < 0.3334 -> "low"
      p when p >= 0.6667 -> "high"
      _ -> "medium"
    end
  end

  defp state(%{} = _device, %{} = _characteristic, _value), do: "neutral"

  defp style(%{} = _device, %{type: "numeric"} = characteristic, value) do
    scale = numeric_to_scale(characteristic, value)
    min_hue = 0
    max_hue = 220
    hue = max_hue - (scale * (max_hue - min_hue)) |> limit_number(min_hue, max_hue)
    "--value-color: hsl(#{hue}deg 71% 53%)"
  end

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
end
