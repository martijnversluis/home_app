defmodule Nmap.Scanner do
  def scan(ip_range) do
    case Porcelain.exec("nmap", ["-sPn", "-oX", "-", ip_range]) do
      %{out: xml, status: 0} -> Nmap.Xml.Parser.parse!(xml)
      _ -> {:err, "NMap scan failed"}
    end
  end

  def scan!(ip_range) do
    {:ok, result} = scan(ip_range)
    result
  end
end
