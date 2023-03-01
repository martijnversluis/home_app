defmodule CheapEnergy.Definition do
  alias HomeApp.Definition.{Characteristic, DeviceType}

  def device_types() do
    %{
      cheap_hours: %DeviceType{
        characteristics: %{
          active: Characteristic.boolean(),
          date_time: Characteristic.date_time(),
          price: Characteristic.money("euro")
        },
        label: ["name", "date_time", "price"],
        icon: "arrow-growth"
      }
    }
  end
end
