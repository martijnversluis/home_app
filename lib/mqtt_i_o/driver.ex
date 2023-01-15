defmodule MqttIO.Driver do
  use HomeApp.DeviceDriver, monitor_with: MqttIO.Monitor

  defp get_device_value(interface, device_infos, state) when is_list(device_infos), do: %{}
end
