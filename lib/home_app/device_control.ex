defmodule HomeApp.DeviceControl do
  alias HomeApp.{Configuration, ConfigurationAgent}

  def dispatch(devices, action, parameters \\ %{})

  def dispatch(devices, action, parameters) when is_list(devices) do
    Enum.each(devices, fn device ->
      dispatch(device, action, parameters)
    end)
  end

  def dispatch(%{interface_type: interface_type} = device, action, parameters) do
    driver = get_driver!(interface_type)

    case action do
      "activate" -> driver.activate(device)
      "deactivate" -> driver.deactivate(device)
      "blink" -> driver.blink(device)
      "change" -> driver.change(device, parameters)
    end
  end

  def get_value(%{type: interface_type} = interface, devices) do
    device_infos =
      ConfigurationAgent.get_configuration()
      |> Configuration.get_device_info(devices)

    get_driver!(interface_type).get_value(interface, device_infos)
  end

  def get_value(%{interface_type: interface_type} = device) do
    get_value(get_driver!(interface_type), device)
  end

  def get_value(driver, device) do
    try do
      driver.get_value(device)
    catch
      :exit, _value -> {:error, :no_connection}
    end
  end

  def get_driver(interface_type) do
    case Application.get_env(:home_app, :device_drivers, [])
         |> Keyword.get(String.to_atom(interface_type)) do
      nil -> {:error, "No driver configured for #{interface_type}"}
      driver -> {:ok, driver}
    end
  end

  def get_driver!(interface_type) do
    {:ok, driver} = get_driver(interface_type)
    driver
  end
end
