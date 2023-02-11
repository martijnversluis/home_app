defmodule Smoov.Driver do
  use HomeApp.DeviceDriver

  defp get_device_value(_interface, devices, _state) when is_list(devices) do
    Map.new(devices, fn %{id: id, config: %{id: charge_point_id}} ->
      {
        id,
        {
          :ok,
          Smoov.Client.get_charge_point(charge_point_id) |> stringify_keys()
        }
      }
    end)
  end
end
