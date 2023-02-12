defmodule HomeApp.Configuration.DeviceType do
  use HomeApp.Configuration.Schema
  alias HomeApp.Configuration.Characteristic

  schema "" do
    field(:id, :string)
    field(:connection, :string)
    embeds_many(:characteristics, Characteristic)
    field(:icon, :string)
    field(:label, {:array, :string}, default: [])
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :connection, :icon, :label])
    |> cast_embed(:characteristics, required: true)
    |> validate_required([:id, :icon])
  end
end
