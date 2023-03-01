defmodule Entsoe.Xml.Parser do
  def parse(xml) do
    Saxy.parse_string(xml, Entsoe.Xml.EventHandler, [])
  end

  def parse!(xml) do
    {:ok, document} = parse(xml)
    document
  end
end
