defmodule WasteCalendar.Definition do
  alias HomeApp.Definition.{Characteristic, DeviceType}

  def device_types() do
    %{
      waste_calendar: %DeviceType{
        characteristics: %{
          active: Characteristic.boolean(),
          waste_type: Characteristic.enum(~w[GRAY GREEN PAPER PACKAGES]),
          date: Characteristic.date()
        },
        label: ["date", "waste_type"],
        icon: "trash-alt"
      }
    }
  end
end
