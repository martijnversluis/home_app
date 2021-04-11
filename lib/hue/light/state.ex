defmodule Hue.Light.State do
  defstruct on: nil,
            brightness: nil,
            hue: nil,
            saturation: nil,
            xy: nil,
            color_temperature: nil,
            alert: nil,
            effect: nil,
            color_mode: nil,
            mode: nil,
            reachable: nil

  def parse(
    %{
      "on" => on,
      "alert" => alert,
      "mode" => mode,
      "reachable" => reachable
    } = data
      ) do
    %__MODULE__{
      on: on,
      brightness: data["bri"],
      hue: data["hue"],
      saturation: data["sat"],
      xy: data["xy"],
      color_temperature: data["ct"],
      alert: alert,
      effect: data["effect"],
      color_mode: data["colormode"],
      mode: mode,
      reachable: reachable
    }
  end
end
