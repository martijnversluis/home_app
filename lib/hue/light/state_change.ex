defmodule Hue.Light.StateChange do
  defstruct on: nil,
            brightness: nil,
            hue: nil,
            saturation: nil,
            xy: nil,
            color_temperature: nil,
            alert: nil,
            effect: nil,
            transition_time: nil,
            brightness_increment: nil,
            saturation_increment: nil,
            hue_increment: nil,
            color_temperature_increment: nil,
            xy_increment: nil

  def translate_to_hue(
        %__MODULE__{
          on: on,
          brightness: brightness,
          hue: hue,
          saturation: saturation,
          xy: xy,
          color_temperature: color_temperature,
          alert: alert,
          effect: effect,
          transition_time: transition_time,
          brightness_increment: brightness_increment,
          saturation_increment: saturation_increment,
          hue_increment: hue_increment,
          color_temperature_increment: color_temperature_increment,
          xy_increment: xy_increment
        } = _state_change
      ) do
    %{
      on: on,
      bri: parse_brightness(brightness),
      hue: hue,
      sat: saturation,
      xy: xy,
      ct: color_temperature,
      alert: alert,
      effect: effect,
      transitiontime: transition_time,
      bri_inc: brightness_increment,
      sat_inc: saturation_increment,
      hue_inc: hue_increment,
      ct_inc: color_temperature_increment,
      xy_inc: xy_increment
    }
  end

  defp parse_brightness(nil), do: nil
  defp parse_brightness(brightness) when is_integer(brightness), do: brightness

  defp parse_brightness(brightness) when is_float(brightness) do
    brightness
    |> Float.round(0)
    |> Kernel.trunc()
  end

  defp parse_brightness(brightness) when is_binary(brightness) do
    case Integer.parse(brightness) do
      {value, _} -> value
      :error -> nil
    end
  end
end
