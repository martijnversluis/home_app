defmodule Nmap.Xml.Parser do
  def parse(xml) do
    {
      :ok,
      Saxy.parse_string(xml, Nmap.Xml.EventHandler, [])
    }
  end

  def parse!(xml) do
    {:ok, report} = parse(xml)
    report
  end
end
