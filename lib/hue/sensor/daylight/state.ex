defmodule Hue.Sensor.Daylight.State do
  defstruct daylight: nil

  def parse(%{"daylight" => daylight}) do
    %__MODULE__{daylight: daylight}
  end
end
