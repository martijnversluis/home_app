defmodule Nmap.Xml.EventHandler do
  @behaviour Saxy.Handler
  alias Nmap.Run
  alias Nmap.Run.{Host}

  def handle_event(:start_document, attributes, _state), do: {:ok, %Run{}}

  def handle_event(:start_element, {"host", _attributes}, %{hosts: hosts} = run) do
    {
      :ok,
      run |> Map.put(:hosts, [%Host{}] ++ hosts)
    }
  end

  def handle_event(:start_element, {"status", attributes}, %Run{} = run) do
    run
    |> update_host(fn host ->
      parse_host_attributes(host, Map.new(attributes))
    end)
  end

  def handle_event(:start_element, {"address", attributes}, %Run{} = run) do
    run
    |> update_host(fn host ->
      parse_host_address(host, Map.new(attributes))
    end)
  end

  def handle_event(:start_element, {"hostname", attributes}, %Run{} = run) do
    run
    |> update_host(fn host ->
      parse_hostname(host, Map.new(attributes))
    end)
  end

  def handle_event(:start_element, {_element, _attributes}, run), do: {:ok, run}
  def handle_event(:end_element, _name, run), do: {:ok, run}
  def handle_event(:characters, _characters, run), do: {:ok, run}
  def handle_event(:end_document, _characters, run), do: {:ok, run}

  defp update_host(%Run{hosts: [host | other_hosts]} = run, update_func) do
    {
      :ok,
      run |> Map.put(:hosts, [update_func.(host) | other_hosts])
    }
  end

  defp parse_host_attributes(%Host{} = host, %{"state" => state} = _attributes) do
    host |> Map.put(:state, state)
  end

  defp parse_host_address(%Host{} = host, %{"addr" => address, "addrtype" => "ipv4"}) do
    host |> Map.put(:ip, address)
  end

  defp parse_host_address(%Host{} = host, %{"addr" => address, "addrtype" => "mac"} = attributes) do
    host
    |> Map.put(:mac, address)
    |> Map.put(:vendor, Map.get(attributes, "vendor"))
  end

  defp parse_hostname(%Host{hostnames: hostnames} = host, %{"name" => hostname}) do
    host |> Map.put(:hostnames, hostnames ++ [hostname])
  end
end
