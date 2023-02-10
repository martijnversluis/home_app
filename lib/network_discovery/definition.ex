defmodule NetworkDiscovery.Definition do
  alias HomeApp.Definition.{Characteristic, DeviceType}

  def device_types() do
    %{
      network_device: %DeviceType {
        characteristics: %{
          id: Characteristic.string(),
          ip: Characteristic.string(),
          mac: Characteristic.string(),
          online?: Characteristic.boolean()
        },
        icon: "server-network"
      }
    }
  end
end
