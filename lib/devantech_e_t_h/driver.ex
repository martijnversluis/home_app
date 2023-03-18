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
            config: %{pin: pin}
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
            config: %{pin: pin}
          } = _device
        },
        _,
        client
      ) do
    {:reply, Client.set_relay_off(client, pin), client}
  end

  defp get_device_value(
         _interface,
         %{
           device_type: %{
             id: "devantech_eth_analogue_input"
           },
           config:
             %{
               pin: pin,
               voltage_range: %{min: min_voltage, max: max_voltage},
               value_range: %{min: min_value, max: max_value}
             } = device_config
         } = _device,
         client
       ) do
    case Client.get_analogue_input(client, pin) do
      {:ok, voltage} ->
        ratio = voltage / (max_voltage - min_voltage)
        value = min_value + (max_value - min_value) * ratio

        {
          :ok,
          %{"value" => round_device_value(value, device_config)}
        }

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_device_value(interface, device_infos, state) when is_list(device_infos) do
    Map.new(device_infos, fn %{id: id} = device_info ->
      {id, get_device_value(interface, device_info, state)}
    end)
  end

  defp get_device_value(
         _interface,
         %{
           config: %{pin: pin},
           device_type: %{id: "devantech_eth_relay"}
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
           config: %{pin: pin},
           device_type: %{id: "devantech_eth_digital_input"}
         } = _device,
         client
       ) do
    case Client.get_input(client, pin) do
      {:ok, state} -> {:ok, %{"on" => state}}
      {:error, error} -> {:error, error}
    end
  end

  defp round_device_value(value, %{decimals: decimals} = _device_config)
       when is_integer(decimals) do
    Float.round(value, decimals)
  end

  defp round_device_value(value, %{} = _device_config), do: value
end
