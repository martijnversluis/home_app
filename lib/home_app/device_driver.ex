defmodule HomeApp.DeviceDriver do
  def dispatch(%{interface_type: interface_type} = device, action) do
    driver = get_driver!(interface_type)

    case action do
      "activate" -> driver.activate(device)
      "deactivate" -> driver.deactivate(device)
    end
  end

  def get_value(%{interface_type: interface_type} = device) do
    get_driver!(interface_type).get_value(device)
  end

  def get_driver(interface_type) do
    case Application.get_env(:home_app, :device_drivers, []) |> Keyword.get(String.to_atom(interface_type)) do
      nil -> {:error, "No driver configured for #{interface_type}"}
      driver -> {:ok, driver}
    end
  end

  def get_driver!(interface_type) do
    {:ok, driver} = get_driver(interface_type)
    driver
  end
end
