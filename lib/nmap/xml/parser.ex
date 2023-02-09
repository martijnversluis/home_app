defmodule Nmap.Xml.Parser do
  def parse!(xml) do
    {:ok, report} = Saxy.parse_string(xml, Nmap.Xml.EventHandler, [])
    report
  end
end
