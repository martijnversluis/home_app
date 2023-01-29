
defmodule HomeAppWeb.DeviceHelpers do
  alias HomeApp.Configuration
  import Phoenix.HTML.Tag

  def device_control(
        %{id: device_id, value: value} = _device,
        %{
          id: characteristic_id,
          type: "numeric",
          writable: true,
          range: %{min: min, max: max}
        } = characteristic
      ) do
    tag(
      :input,
      class: "device__slider",
      id: "#{device_id}_#{characteristic_id}",
      max: max,
      min: min,
      name: "#{device_id}_#{characteristic_id}",
      type: "range",
      value: get_value(value, characteristic),
      "phx-value-device-id": device_id,
      "phx-value-characteristic": characteristic_id,
      "phx-hook": "NumericSlider",
      "phx-click": ""
    )
  end

  def device_control(_device, %{} = _characteristic), do: nil

  def devices_by_room(
        %{} = configuration,
        %{} = values
      ) do
    (device_infos(configuration, values) ++ group_infos(configuration, values))
    |> Enum.group_by(fn entity -> entity.room end)
    |> Enum.map(fn {room_id, entities} ->
      {
        Configuration.get_room(configuration, room_id),
        entities
      }
    end)
    |> Enum.sort_by(fn {room, _devices} -> room.name end)
  end

  defp device_infos(%{devices: devices} = configuration, values) do
    devices
    |> Enum.sort_by(fn %{} = device -> device.type end)
    |> Enum.map(fn device ->
      device_info(device, configuration, Map.fetch!(values, device.id))
    end)
  end

  defp device_info(%{id: device_id} = device, %{} = configuration, value) do
    %{
      device_type: %{characteristics: characteristics, icon: icon}
    } = Configuration.get_device_info(configuration, device_id)

    %{
      type: "device",
      icon: icon,
      characteristic: characteristic_id(characteristics),
      state: state(characteristics, value),
      label: label(device, characteristics, value),
      style: style(device, characteristics, value),
      click_action: click_action(characteristics, value),
      button_icon: button_icon(characteristics, value),
      characteristics: characteristics,
      value: value
    }
    |> Map.merge(device)
  end

  defp group_infos(%{groups: groups} = configuration, values) do
    groups
    |> Enum.sort_by(fn %{} = group -> group.id end)
    |> Enum.map(fn group ->
      group_info(
        group,
        configuration,
        Enum.map(group.devices, fn device_id -> Map.fetch!(values, device_id) end)
      )
    end)
  end

  defp group_info(
         %{devices: group_device_ids} = group,
         %{} = configuration,
         values
       ) do
    group_devices = Configuration.get_device_info(configuration, group_device_ids)

    all_characteristic_ids =
      group_devices
      |> Enum.reduce([], fn device, acc -> acc ++ device.characteristic_ids end)
      |> Enum.uniq()

    common_characteristic_ids =
      all_characteristic_ids
      |> Enum.reject(fn characteristic ->
        Enum.any?(group_devices, fn device ->
          !Enum.member?(device.characteristic_ids, characteristic)
        end)
      end)

    common_characteristics =
      Configuration.get_characteristics(configuration, common_characteristic_ids)

    grouped_values = group_values(common_characteristics, values)

    %{
      type: "group",
      click_action: click_action(common_characteristics, grouped_values),
      state: state(common_characteristics, grouped_values),
      label: label(group, common_characteristics, grouped_values),
      button_icon: button_icon(common_characteristics, grouped_values),
      characteristics: common_characteristics,
      value: grouped_values
    }
    |> Map.merge(group)
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

  defp get_group_value(%{type: "binary"} = _characteristic, values), do: Enum.all?(values)

  defp get_group_value(%{type: "numeric"} = _characteristic, values) do
    Enum.sum(values) / Enum.count(values)
  end

  defp group_values(characteristics, values) do
    characteristics
    |> Enum.map(fn characteristic ->
      {
        characteristic.id,
        get_group_value(
          characteristic,
          Enum.map(values, fn value -> get_value(value, characteristic) end)
        )
      }
    end)
    |> Map.new()
  end

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

  defp label(%{name: device_name} = _device, %{type: "binary"} = _characteristic, _value),
    do: device_name

  defp label(%{} = _device, %{type: "numeric"} = _characteristic, nil = _value), do: "-"
  defp label(%{} = _device, %{type: "string"} = _characteristic, value), do: value

  defp label(
         %{} = _device,
         %{type: "numeric", unit: unit, decimals: decimals} = _characteristic,
         value
       ) do
    "#{round_numeric_value(value, decimals)} #{unit}"
  end

  defp label(%{} = _device, %{type: "timestamp"} = _characteristic, value) do
    "#{value}"
    |> Timex.parse!("{s-epoch}")
    |> Timex.format!("{relative}", :relative)
  end

  defp round_numeric_value(value, nil), do: value

  defp round_numeric_value(value, decimals) when is_integer(decimals),
    do: Float.ceil(value, decimals)

  defp state(characteristics, value) when is_list(characteristics) do
    characteristic = List.first(characteristics)
    state(characteristic, get_value(value, characteristic))
  end

  defp state(%{} = _characteristic, nil = _value), do: "unknown"

  defp state(%{type: "binary", states: %{on: on_state, off: off_state}} = _characteristic, value) do
    case value |> binary_state() do
      true -> on_state
      false -> off_state
    end
  end

  defp state(%{type: "numeric", range: %{min: _min, max: _max}} = characteristic, value) do
    case numeric_to_scale(characteristic, value) do
      p when p < 0.3334 -> "low"
      p when p >= 0.6667 -> "high"
      _ -> "medium"
    end
  end

  defp state(%{} = _characteristic, _value), do: "neutral"

  defp binary_state(true), do: true
  defp binary_state(false), do: false
  defp binary_state(0.0), do: false
  defp binary_state(0), do: false
  defp binary_state(1.0), do: true
  defp binary_state(1), do: true
  defp binary_state(nil), do: false

  defp binary_state(float) when is_float(float) do
    round(float) |> binary_state()
  end

  defp style(device, characteristics, value) when is_list(characteristics) do
    characteristic = List.first(characteristics)
    style(device, characteristic, get_value(value, characteristic))
  end

  defp style(%{} = _device, %{} = _characteristic, _value), do: ""

  defp numeric_to_scale(%{type: "numeric", range: %{min: min, max: max}} = _characteristic, value) do
    value / (max - min)
  end

  defp get_value(nil = _value, _characteristic), do: nil
  defp get_value(%{} = value, %{source: source} = _characteristic), do: Map.fetch!(value, source)
end
