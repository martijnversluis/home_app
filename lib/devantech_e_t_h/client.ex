defmodule DevantechETH.Client do
  use Connection

  @get_status 0x30
  @set_relay 0x31
  @set_output 0x32
  @get_relays 0x33
  @get_inputs 0x34
  @get_analogue 0x35
  @get_counters 0x36

  @module_ids %{
    0x1F => "dS1242"
  }

  def start_link(host, port, :binary = mode) do
    Connection.start_link(__MODULE__, {host, port, mode})
  end

  def tcp_send(conn, data), do: Connection.call(conn, {:send, data})

  def tcp_recv(conn, bytes, timeout \\ 3000) do
    Connection.call(conn, {:recv, bytes, timeout})
  end

  def close(conn), do: Connection.call(conn, :close)

  def init({host, port, :binary = mode}) do
    s = %{host: parse_host(host), port: parse_port(port), mode: mode, sock: nil}
    {:connect, :init, s}
  end

  def connect(_, %{sock: nil, host: host, port: port, mode: _mode} = s) do
    case :gen_tcp.connect(host, port, [:binary, active: false], 5000) do
      {:ok, sock} ->
        {:ok, %{s | sock: sock}}
      {:error, _} ->
        {:backoff, 1000, s}
    end
  end

  def disconnect(info, %{sock: sock} = s) do
    :ok = :gen_tcp.close(sock)
    case info do
      {:close, from} ->
        Connection.reply(from, :ok)
      {:error, :closed} ->
        :error_logger.format("Connection closed~n", [])
      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format("Connection error: ~s~n", [reason])
    end
    {:connect, :reconnect, %{s | sock: nil}}
  end

  def handle_call(_, _, %{sock: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:send, data}, _, %{sock: sock} = s) do
    case :gen_tcp.send(sock, data) do
      :ok ->
        {:reply, :ok, s}
      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call({:recv, bytes, timeout}, _, %{sock: sock} = s) do
    case :gen_tcp.recv(sock, bytes, timeout) do
      {:ok, _value} = ok ->
        {:reply, ok, s}
      {:error, :timeout} = timeout ->
        {:reply, timeout, s}
      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  def get_status(socket) do
    send_and_receive(socket, [@get_status], 8,
      fn <<
           module_id::8,
           system_firmware_major::8,
           system_firmware_minor::8,
           application_firmware_major::8,
           application_firmware_minor::8,
           volts::8,
           internal_temperature::16
         >> ->
        %DevantechETH.Status{
          module_id: Map.fetch!(@module_ids, module_id),
          system_firmware: "#{system_firmware_major}.#{system_firmware_minor}",
          application_firmware: "#{application_firmware_major}.#{application_firmware_minor}",
          volts: volts / 10.0,
          internal_temperature: internal_temperature / 10.0
        }
      end
    )
  end

  def set_relay_on(socket, relay_number) do
    set_relay(socket, [relay_number, 1, 0, 0, 0, 0])
  end

  def set_relay_off(socket, relay_number) do
    set_relay(socket, [relay_number, 0, 0, 0, 0, 0])
  end

  def pulse_relay(socket, relay_number, pulse_time_ms) do
    <<b1::8,b2::8,b3::8,b4::8>>=<<pulse_time_ms::32>>
    set_relay(socket, [relay_number, 0, b1, b2, b3, b4])
  end

  def set_output_on(socket, io_number) do
    send_and_receive(socket, [@set_output, io_number, 1], 1, fn <<0>> -> true end)
  end

  def set_output_off(socket, io_number) do
    send_and_receive(socket, [@set_output, io_number, 0], 1, fn <<0>> -> true end)
  end

  def get_relays(socket) do
    send_and_receive(socket, [@get_relays, 1], 5,
      fn <<_first_byte::8, status_bytes::32>> ->
        bit_list_to_map(<<status_bytes::32>>)
      end
    )
  end

  def get_relay(socket, relay_number) do
    send_and_receive(socket, [@get_relays, relay_number], 5, fn <<status::8, _rest::32>> -> status == 1 end)
  end

  def get_inputs(socket) do
    send_and_receive(socket, [@get_inputs, 1], 2,
      fn <<_first_byte::8, status_bits::8>> ->
        bit_list_to_map(<<status_bits::4>>)
      end
    )
  end

  def get_input(socket, input_number) do
    send_and_receive(socket, [@get_inputs, input_number], 2,
      fn <<status::8, _rest::8>> ->
        status == 1
      end
    )
  end

  def get_analogue_inputs(socket) do
    send_and_receive(socket, [@get_analogue], 4,
      fn <<input_1::16, input_2::16>> ->
        %{
          1 => value_to_volts(input_1),
          2 => value_to_volts(input_2)
        }
      end
    )
  end

  def get_analogue_input(socket, input_number) do
    case get_analogue_inputs(socket) do
      {:ok, %{} = values} ->
        {:ok, Map.fetch!(values, input_number)}
      {:error, error} ->
        {:error, error}
    end
  end

  def get_counter(socket, counter_number) do
    send_and_receive(socket, [@get_counters, counter_number], 8,
      fn <<counter_value::32, capture_register::32>> ->
        {counter_value, capture_register}
      end
    )
  end

  defp bit_list_to_map(bit_list) do
    bits = for <<b::1 <- bit_list >>, do: b
    range = Range.new(Enum.count(bits) - 1, 0)

    Enum.reduce(range, %{}, fn i, acc ->
      Map.put(acc, i + 1, Enum.at(bits, i) == 1)
    end)
  end

  defp set_relay(socket, bytes) do
    send_and_receive(socket, [@set_relay] ++ bytes, 1, fn <<0>> -> true end)
  end

  defp send_and_receive(socket, message, response_byte_count, response_fun) do
    case tcp_send(socket, message) do
      :ok ->
        {:ok, bytes} = tcp_recv(socket, response_byte_count)
        result = response_fun.(bytes)
        {:ok, result}
      {:error, error} ->
        {:error, error}
    end
  end

  defp parse_host({_a, _b, _c, _d} = addr), do: addr

  defp parse_host(host) when is_binary(host) do
    [a, b, c, d] =
      String.split(host, ".")
      |> Enum.map(fn token ->
        {int, _reset} = Integer.parse(token)
        int
      end)
    {a, b, c, d}
  end

  defp parse_port(port) when is_integer(port), do: port
  defp parse_port(port) when is_binary(port) do
    {int, _rest} = Integer.parse(port)
    int
  end

  defp value_to_volts(value) do
    max_value = 1023
    max_voltage = 3.3
    (max_voltage / max_value) * value
  end
end
