defmodule DevantechETH.Driver do
  alias DevantechETH.Client
  use HomeApp.DeviceDriver

  def init({%{host: host, port: port} = _interface}) do
    {:ok, client} = Client.start_link(host, port, :binary)
    {:ok, client}
  end

  def activate(interface, device_info),
    do: GenServer.call(name(interface), {:activate, interface, device_info})

  def deactivate(interface, device_info),
    do: GenServer.call(name(device_info), {:deactivate, interface, device_info})

  def handle_call(
        {
          :activate,
          _interface,
          %{
            device_type: %{id: "devantech_eth_relay"},
            pin: pin
          } = _device
        },
        _,
        client
      ) do
    {:reply, Client.set_relay_on(client, pin), client}
  end

  def handle_call(
        {
          :deactivate,
          _interface,
          %{
            device_type: %{id: "devantech_eth_relay"},
            pin: pin
          } = _device
        },
        _,
        client
      ) do
    {:reply, Client.set_relay_off(client, pin), client}
  end

  defp get_device_value(interface, device_infos, state) when is_list(device_infos) do
    Map.new(device_infos, fn %{id: id} = device_info ->
      {id, get_device_value(interface, device_info, state)}
    end)
  end

  defp get_device_value(
         _interface,
         %{
           pin: pin,
           device_type: %{
             id: "devantech_eth_analogue_input"
           },
           config: %{
             voltage_range: %{min: min_voltage, max: max_voltage},
             value_range: %{min: min_value, max: max_value}
           }
         } = _device,
         client
       ) do
    case Client.get_analogue_input(client, pin) do
      {:ok, voltage} ->
        ratio = voltage / (max_voltage - min_voltage)
        value = min_value + (max_value - min_value) * ratio
        {:ok, %{"voltage" => value}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_device_value(
         _interface,
         %{
           pin: pin,
           device_type: %{id: "devantech_eth_relay"},
         } = _device,
         client
       ) do
    case Client.get_relay(client, pin) do
      {:ok, state} -> {:ok, %{"on" => state}}
      {:error, error} -> {:error, error}
    end
  end

  defp get_device_value(
         _interface,
         %{
           pin: pin,
           device_type: %{id: "devantech_eth_digital_input"}
         } = _device,
         client
       ) do
    case Client.get_input(client, pin) do
      {:ok, state} -> {:ok, %{"on" => state}}
      {:error, error} -> {:error, error}
    end
  end
end
