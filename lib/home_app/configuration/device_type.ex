defmodule HomeApp.Configuration.DeviceType do
  use HomeApp.Configuration.Schema
  alias HomeApp.Configuration.Characteristic

  schema "" do
    field(:id, :string)
    field(:connection, :string)
    embeds_many(:characteristics, Characteristic)
    field(:icon, :string)
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :connection, :icon])
    |> cast_embed(:characteristics)
    |> validate_required([:id, :characteristics, :icon])
  end
end
