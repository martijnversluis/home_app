defmodule HomeApp.Configuration.DeviceType do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:connection, :string)
    field(:characteristics, {:array, :string}, default: [])
    field(:icon, :string)
    field(:config, HomeApp.Configuration.Config, default: %{})
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :connection, :characteristics, :icon, :config])
    |> validate_required([:id, :connection, :characteristics, :icon])
  end
end
