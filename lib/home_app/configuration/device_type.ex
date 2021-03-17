defmodule HomeApp.Configuration.DeviceType do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:connection, :string)
    field(:characteristic, :string)
    field(:icon, :string)
    field(:config, HomeApp.Configuration.Config, default: %{})
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :connection, :characteristic, :icon, :config])
    |> validate_required([:id, :connection, :characteristic, :icon])
  end
end
