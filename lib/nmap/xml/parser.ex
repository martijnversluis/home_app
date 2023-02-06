defmodule Nmap.Xml.Parser do
  def parse!(filepath) do
    {:ok, report} =
      filepath
      |> File.read!()
      |> Saxy.parse_string(Nmap.Xml.EventHandler, [])
    report
  end
end
