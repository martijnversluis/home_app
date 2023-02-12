defmodule Arp.Scanner do
  @regex ~r/\(([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\) at (([0-9a-f]{1,2}:[0-9a-f]{1,2}:[0-9a-f]{1,2}:[0-9a-f]{1,2}:[0-9a-f]{1,2}:[0-9a-f]{1,2})|\(incomplete\)) on (\S+)/

  def scan do
    case Porcelain.exec("arp", ["-na"]) do
      %{out: output, status: 0} -> {:ok, parse(output)}
      _ -> {:err, "Arp scan failed"}
    end
  end

  def scan!() do
    {:ok, result} = scan()
    result
  end

  def parse(output) do
    Regex.scan(@regex, output)
    |> Enum.map(fn [_full_match, ip, mac, _, interface] ->
      %Arp.Result{ip: ip, mac: mac, interface: interface}
    end)
  end
end
