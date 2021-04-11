defmodule HomeApp.Configuration.Group do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:room, :string, default: nil)
    field(:devices, {:array, :string}, default: [])
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :room, :devices])
    |> validate_required([:id])
  end
end
