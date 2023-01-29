defmodule MqttIO.Definition do
  alias HomeApp.Definition.DeviceType

  def device_types() do
    %{
      digital_input: DeviceType.binary_sensor()
    }
  end
end
