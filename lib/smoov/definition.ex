defmodule Smoov.Definition do
  alias HomeApp.Definition.{Characteristic, DeviceType}

  def device_types() do
    %{
      charge_point: %DeviceType{
        characteristics: %{
          id: Characteristic.string(),
          address: Characteristic.string(),
          location: Characteristic.location(),
          available?: Characteristic.boolean()
        },
        icon: "plug",
        id: :smoov_charge_point
      }
    }
  end
end
