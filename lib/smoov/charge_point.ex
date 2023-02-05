defmodule Smoov.ChargePoint do
  alias Smoov.Connector

  defstruct id: nil,
            address: nil,
            location: nil,
            connectors: [],
            available?: nil

  def parse(
        %{
          "id" => id,
          "address" => %{
            "addressLine1" => address,
            "city" => city
          },
          "location" => %{
            "latitude" => latitude,
            "longitude" => longitude
          },
          "evses" => connector_data
        } = _data
      ) do
    connectors = Connector.parse(connector_data)

    %__MODULE__{
      id: id,
      address: address <> " " <> city,
      location: {latitude, longitude},
      connectors: connectors,
      available?: Enum.any?(connectors, fn connector -> connector.available? end)
    }
  end
end
