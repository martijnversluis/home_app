defmodule DevantechETH.Driver do
  alias DevantechETH.Client
  use HomeApp.DeviceDriver

  def init({%{host: host, port: port} = _interface}) do
    {:ok, client} = Client.start_link(host, port, :binary)
    {:ok, client}
  end

  def activate(device_info), do: GenServer.call(name(device_info), {:activate, device_info})
  def deactivate(device_info), do: GenServer.call(name(device_info), {:deactivate, device_info})
  def get_value(device_info), do: GenServer.call(name(device_info), {:get_value, device_info})

  def handle_call(
        {:activate, %{connection: "devantech_eth_relay", pin: pin} = _device},
        _,
        client
      ) do
    {:reply, Client.set_relay_on(client, pin), client}
  end

  def handle_call(
        {:deactivate, %{connection: "devantech_eth_relay", pin: pin} = _device},
        _,
        client
      ) do
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
        value = min_value + (max_value - min_value) * ratio

        {
          :reply,
          {:ok, %{"voltage" => value}},
          client
        }

      {:error, error} ->
        {:reply, {:error, error}, client}
    end
  end

  def handle_call(
        {:get_value, %{pin: pin, connection: "devantech_eth_relay"} = _device},
        _,
        client
      ) do
    case Client.get_relay(client, pin) do
      {:ok, state} ->
        {:reply, {:ok, %{"on" => state}}, client}

      {:error, error} ->
        {:reply, {:error, error}, client}
    end
  end

  def handle_call(
        {:get_value, %{pin: pin, connection: "devantech_eth_digital_input"} = _device},
        _,
        client
      ) do
    case Client.get_input(client, pin) do
      {:ok, state} ->
        {:reply, {:ok, %{"on" => state}}, client}

      {:error, error} ->
        {:reply, {:error, error}, client}
    end
  end
end
