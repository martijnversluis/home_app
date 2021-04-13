defmodule HomeApp.Configuration.Group do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:name, :string)
    field(:room, :string, default: nil)
    field(:icon, :string)
    field(:devices, {:array, :string}, default: [])
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :name, :room, :devices, :icon])
    |> validate_required([:id, :icon])
    |> HomeApp.Configuration.ensure_name()
  end
end
