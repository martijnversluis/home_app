defmodule HomeApp.Definition.DeviceType do
  alias HomeApp.Definition.Characteristic
  defstruct characteristics: [], icon: nil, id: nil

  def binary_sensor(opts \\ []) do
    [icon: icon] = Keyword.merge([icon: "eye"], opts)

    %__MODULE__{
      characteristics: %{
        on: Characteristic.boolean()
      },
      icon: icon,
      id: :binary_sensor
    }
  end

  def analogue_sensor(opts \\ []) do
    [icon: icon, range: range] = Keyword.merge([icon: "tachometer-fast", range: nil], opts)

    %__MODULE__{
      characteristics: %{
        value: Characteristic.numeric(range: range)
      },
      icon: icon,
      id: :analogue_sensor
    }
  end

  def switch(opts \\ []) do
    [icon: icon] = Keyword.merge([icon: "power"], opts)

    %__MODULE__{
      characteristics: %{
        on: Characteristic.boolean(writable: true)
      },
      icon: icon,
      id: :switch
    }
  end

  def light(opts \\ []) do
    [icon: icon] = Keyword.merge([icon: "lightbulb"], opts)

    %__MODULE__{
      characteristics: %{
        on: Characteristic.boolean(writable: true),
        brightness: Characteristic.percentage(writable: true)
      },
      icon: icon,
      id: :light
    }
  end
end
