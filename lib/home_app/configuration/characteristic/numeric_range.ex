defmodule HomeApp.Configuration.Characteristic.NumericRange do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:min, :float)
    field(:max, :float)
  end

  def changeset(struct, attributes) do
    cast(struct, attributes, [:min, :max], empty_values: ["", nil])
  end
end
