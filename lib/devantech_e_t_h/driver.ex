defmodule DevantechETH.Driver do
  alias DevantechETH.Client
  use GenServer

  def start_link({interface}) do
    GenServer.start_link(__MODULE__, {interface}, name: name(interface))
  end

  def init({%{host: host, port: port} = _interface}) do
    {:ok, client} = Client.start_link(host, port, :binary)
    {:ok, client}
  end

  defp name(%{interface: id, interface_type: type} = _device_info), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")
  defp name(%{id: id, type: type} = _interface), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

  def activate(device_info), do: GenServer.call(name(device_info), {:activate, device_info})
  def deactivate(device_info), do: GenServer.call(name(device_info), {:deactivate, device_info})
  def get_value(device_info), do: GenServer.call(name(device_info), {:get_value, device_info})

  def handle_call({:activate, %{connection: "devantech_eth_relay", pin: pin} = _device}, _, client) do
    {:reply, Client.set_relay_on(client, pin), client}
  end

  def handle_call({:deactivate, %{connection: "devantech_eth_relay", pin: pin} = _device}, _, client) do
    {:reply, Client.set_relay_off(client, pin), client}
  end

  def handle_call(
        {
          :get_value,
          %{
            pin: pin,
            connection: "devantech_eth_analogue_input",
            config: %{
              voltage_range: %{min: min_voltage, max: max_voltage},
              value_range: %{min: min_value, max: max_value}
            }
          } = _device
        },
        _,
        client
      ) do
    case Client.get_analogue_input(client, pin) do
      {:ok, voltage} ->
        ratio = voltage / (max_voltage - min_voltage)
        value = min_value + ((max_value - min_value) * ratio)
        {:reply, {:ok, value}, client}
      {:error, error} ->
        {:reply, {:error, error}, client}
    end
  end

  def handle_call({:get_value, %{pin: pin, connection: "devantech_eth_relay"} = _device}, _, client) do
    {:reply, Client.get_relay(client, pin), client}
  end

  def handle_call({:get_value, %{pin: pin, connection: "devantech_eth_digital_input"} = _device}, _, client) do
    {:reply, Client.get_input(client, pin), client}
  end
end
