defmodule HomeApp.Configuration.Room do
  alias HomeApp.Configuration
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:name, :string)
    field(:icon, :string)
  end

  def changeset(struct, attributes) do
    cast(struct, attributes, [:id, :name, :icon], empty_values: ["", nil])
    |> validate_required([:id, :icon])
    |> Configuration.ensure_name()
  end
end
