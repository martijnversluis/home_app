defmodule HomeApp.Configuration.Characteristic.BinaryStates do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:off, :string, default: "inactive")
    field(:on, :string, default: "active")
  end

  def changeset(struct, attributes) do
    cast(struct, attributes, [:off, :on], empty_values: ["", nil])
    |> validate_inclusion(:off, states())
  end

  def states(), do: ~w[active inactive error danger success]
end
