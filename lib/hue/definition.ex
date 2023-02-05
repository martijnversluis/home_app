defmodule Hue.Definition do
  alias HomeApp.Definition.{Characteristic, DeviceType}

  def device_types() do
    %{
      go: DeviceType.light(),
      light: DeviceType.light(),
      outlet: DeviceType.switch(icon: "plug"),
      daylight_sensor: DeviceType.binary_sensor(icon: "sun"),
      dimmer_switch: %DeviceType{
        characteristics: %{
          button: Characteristic.enum(~w[1 2 3 4]),
          event: Characteristic.enum(~w[initial_press repeat short_release long_release])
        },
        icon: "sliders-v-alt",
        id: :hue_dimmer_switch
      }
    }
  end
end
