defmodule NetworkDiscovery.Driver do
  use HomeApp.DeviceDriver

  def get_value(%{config: %{ip_range: ip_range}} = _interface, devices) do
    available_network_devices = NetworkDiscovery.Scanner.scan(ip_range)

    Map.new(devices, fn %{id: id, config: %{mac_address: mac_address}} ->
      device_state =
        case Enum.find(available_network_devices, fn %{mac: mac} -> mac == mac_address end) do
          nil -> %NetworkDiscovery.Device{mac: mac_address, online?: false}
          device -> device
        end
        |> stringify_keys()
        |> Map.put("id", id)

      {id, {:ok, device_state}}
    end)
  end
end
