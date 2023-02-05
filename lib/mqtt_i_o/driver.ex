defmodule MqttIO.Driver do
  use HomeApp.DeviceDriver, monitor_with: MqttIO.Monitor

  defp get_device_value(_interface, device_infos, _state) when is_list(device_infos), do: %{}
end
