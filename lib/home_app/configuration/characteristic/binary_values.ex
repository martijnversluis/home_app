defmodule HomeApp.Configuration.Characteristic.BinaryValues do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:off, :string)
    field(:on, :string)
  end

  def changeset(struct, attributes) do
    cast(struct, attributes, [:off, :on], empty_values: ["", nil])
    |> validate_required([:off, :on])
  end
end
