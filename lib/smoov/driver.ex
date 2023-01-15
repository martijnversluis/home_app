defmodule Smoov.Driver do
  use HomeApp.DeviceDriver

  defp get_device_value(
         %{config: %{charge_points: charge_point_ids}} = _interface,
         devices,
         _state
       )
       when is_list(devices) do
    IO.inspect(charge_point_ids, label: "Smoov get value")

    Map.new(charge_point_ids, fn charge_point_id ->
      {charge_point_id, {:ok, Smoov.Client.get_charge_point(charge_point_id)}}
    end)
  end
end
