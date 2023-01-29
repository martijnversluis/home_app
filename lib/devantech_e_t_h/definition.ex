defmodule DevantechETH.Definition do
  alias HomeApp.Definition.DeviceType

  def device_types() do
    %{
      digital_input: DeviceType.binary_sensor(),
      analogue_input: DeviceType.analogue_sensor(range: 0..5),
      relay: DeviceType.switch()
    }
  end
end
