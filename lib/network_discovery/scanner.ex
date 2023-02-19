defmodule NetworkDiscovery.Scanner do
  def scan(ip_range) do
    nmap_results = Nmap.Scanner.scan!(ip_range)
    arp_results = Arp.Scanner.scan!()

    nmap_results
    |> Map.fetch!(:hosts)
    |> Enum.map(fn nmap_host ->
      %NetworkDiscovery.Device{
        hostnames: nmap_host.hostnames,
        ip: nmap_host.ip,
        mac: resolve_mac(nmap_host, arp_results),
        online?: nmap_host.state == "up",
        vendor: nmap_host.vendor
      }
    end)
  end

  defp resolve_mac(%{ip: ip, mac: nil}, arp_results) do
    case Enum.find(arp_results, fn arp_host -> arp_host.ip == ip end) do
      %{mac: mac} -> mac
      _ -> nil
    end
  end

  defp resolve_mac(%{mac: mac}, _arp_results), do: mac
end
