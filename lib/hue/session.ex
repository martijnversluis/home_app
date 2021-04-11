defmodule Hue.Session do
  defstruct host: nil, device_type: nil, username: nil

  def new(host, device_type) do
    %__MODULE__{host: host, device_type: device_type}
  end
end
