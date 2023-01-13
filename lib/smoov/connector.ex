defmodule Smoov.Connector do
  @available "Available"

  defstruct id: nil,
            max_power: nil,
            status: nil,
            available?: nil

  def parse(connector_data) when is_list(connector_data) do
    Enum.map(connector_data, fn data -> parse(data) end)
  end

  def parse(%{"id" => id, "maxPower" => max_power, "status" => status}) do
    %__MODULE__{
      id: id,
      max_power: max_power,
      status: status,
      available?: status == @available
    }
  end
end
