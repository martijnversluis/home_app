defmodule HomeAppWeb.DeviceHelpers do
  alias HomeApp.Configuration
  import Phoenix.HTML.Tag

  def device_control(
        %{id: device_id, value: value} = _device,
        %{
          id: characteristic_id,
          type: "percentage",
          writable: true
        } = characteristic
      ) do
    tag(
      :input,
      class: "device__slider",
      id: "#{device_id}_#{characteristic_id}",
      max: 100,
      min: 0,
      name: "#{device_id}_#{characteristic_id}",
      type: "range",
      value: get_value(value, characteristic),
      "phx-value-device-id": device_id,
      "phx-value-characteristic": characteristic_id,
      "phx-hook": "NumericSlider",
      "phx-click": ""
    )
  end

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
    %{device_type: %{characteristics: characteristics, icon: icon, label: label}} =
      Configuration.get_device_info(configuration, device_id)

    %{
      type: "device",
      icon: icon,
      characteristic: characteristic_id(characteristics),
      state: state(characteristics, value),
      label: label(device, characteristics, value, label),
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

    all_characteristics =
      group_devices
      |> Enum.reduce([], fn device, acc -> acc ++ device.device_type.characteristics end)
      |> Enum.uniq()

    all_characteristic_ids =
      all_characteristics |> Enum.map(fn characteristic -> characteristic.id end)

    common_characteristic_ids =
      all_characteristic_ids
      |> Enum.reject(fn characteristic ->
        Enum.any?(group_devices, fn device ->
          !Enum.member?(device.characteristic_ids, characteristic)
        end)
      end)

    common_characteristics =
      all_characteristics
      |> Enum.filter(fn characteristic ->
        Enum.member?(common_characteristic_ids, characteristic.id)
      end)

    grouped_values = group_values(common_characteristics, values)

    %{
      type: "group",
      click_action: click_action(common_characteristics, grouped_values),
      state: state(common_characteristics, grouped_values),
      label: label(group, common_characteristics, grouped_values, nil),
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

  defp get_group_value(%{type: "boolean"} = _characteristic, values), do: Enum.all?(values)

  defp get_group_value(%{type: "numeric"} = _characteristic, values) do
    number_values = Enum.filter(values, fn value -> is_number(value) end)
    Enum.sum(number_values) / Enum.count(number_values)
  end

  defp get_group_value(%{type: "percentage"} = _characteristic, values) do
    case Enum.filter(values, fn value -> is_number(value) end) do
      [] -> 0
      number_values -> Enum.sum(number_values) / Enum.count(number_values)
    end
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

  defp sort_characteristics(characteristics) do
    characteristics
    |> Enum.sort(fn
      %{type: "boolean"}, _ -> true
      _, _ -> false
    end)
  end

  defp click_action(_characteristics, nil = _value), do: nil

  defp click_action(characteristics, value) when is_list(characteristics) do
    characteristics
    |> sort_characteristics()
    |> Enum.find_value(fn characteristic ->
      click_action(characteristic, get_value(value, characteristic))
    end)
  end

  defp click_action(%{type: "boolean", writable: true}, true = _value), do: "deactivate"
  defp click_action(%{type: "boolean", writable: true}, false = _value), do: "activate"
  defp click_action(%{writable: false}, _value), do: nil

  defp label(device, characteristics, value, label) when is_list(characteristics) do
    characteristic = List.first(characteristics)
    label(device, characteristic, get_value(value, characteristic), label, characteristics, value)
  end

  defp label(
         %{name: device_name} = _device,
         %{type: "boolean"} = _characteristic,
         value,
         label,
         all_characteristics,
         all_values
       )
       when is_list(label) do
    Enum.map(label, fn label_part ->
      format_value_for_label(
        Enum.find(all_characteristics, fn %{id: id} -> id == label_part end),
        Map.fetch!(all_values, label_part)
      )
    end)
    |> Enum.join(" ")
  end

  defp format_value_for_label(%{type: "date"} = characteristic, value) do
    value
    |> Timex.to_date()
    |> format_relative_date()
  end

  defp format_relative_date(date) do
    day_diff = Timex.diff(date, Timex.today(), :days)

    cond do
      day_diff == 0 -> "today"
      day_diff == 1 -> "tomorrow"
      day_diff < 7 -> Timex.format!(date, "{WDfull}")
      day_diff < 366 -> Timex.format!(date, "{D} {Mfull}")
      true -> Timex.format!(date, "{D} {Mfull} {YYYY}")
    end
  end

  defp format_value_for_label(%{} = characteristic, value) do
    value
  end

  defp label(
         %{name: device_name} = _device,
         %{type: "boolean"} = _characteristic,
         _value,
         nil,
         _all_characteristics,
         _all_values
       ) do
    device_name
  end

  defp label(
         %{} = _device,
         %{type: "numeric"} = _characteristic,
         nil = _value,
         _label,
         _all_characteristics,
         _all_values
       ),
       do: "-"

  defp label(
         %{} = _device,
         %{type: "string"} = _characteristic,
         value,
         _label,
         _all_characteristics,
         _all_values
       ),
       do: value

  defp label(
         %{} = _device,
         %{type: "enum"} = _characteristic,
         value,
         _label,
         _all_characteristics,
         _all_values
       ),
       do: value

  defp label(
         %{} = _device,
         %{type: "numeric", unit: unit, decimals: decimals} = _characteristic,
         value,
         _label,
         _all_characteristics,
         _all_values
       ) do
    "#{round_numeric_value(value, decimals)} #{unit}"
  end

  defp label(
         %{} = _device,
         %{type: "percentage"} = _characteristic,
         value,
         _label,
         _all_characteristics,
         _all_values
       ) do
    "#{value}%"
  end

  defp label(
         %{} = _device,
         %{type: "timestamp"} = _characteristic,
         value,
         _label,
         _all_characteristics,
         _all_values
       ) do
    "#{value}"
    |> Timex.parse!("{s-epoch}")
    |> Timex.format!("{relative}", :relative)
  end

  defp round_numeric_value(value, nil), do: value

  defp round_numeric_value(value, decimals) when is_integer(decimals),
    do: Float.ceil(value, decimals)

  defp state(characteristics, value) when is_list(characteristics) do
    characteristic = characteristics |> sort_characteristics() |> List.first()
    state(characteristic, get_value(value, characteristic))
  end

  defp state(%{} = _characteristic, nil = _value), do: "unknown"

  defp state(%{type: "boolean"} = _characteristic, value) do
    case value |> binary_state() do
      true -> "active"
      false -> "inactive"
    end
  end

  defp state(%{type: "numeric", range: %{min: _min, max: _max}} = characteristic, value) do
    case numeric_to_scale(characteristic, value) do
      p when p < 0.3334 -> "low"
      p when p >= 0.6667 -> "high"
      _ -> "medium"
    end
  end

  defp state(%{type: "percentage"} = characteristic, value) do
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

  defp numeric_to_scale(%{type: "percentage"} = _characteristic, value) do
    value / 100.0
  end

  defp get_value(nil = _value, _characteristic), do: nil
  defp get_value(%{} = value, %{source: source} = _characteristic), do: Map.fetch!(value, source)
end
