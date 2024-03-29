defmodule HomeApp.Configuration.Device do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:name, :string)
    field(:type, :string)
    field(:room, :string)
    field(:interface, :string)
    field(:monitor_hold, :boolean, default: true)
    field(:config, HomeApp.Configuration.Config)
  end

  def changeset(struct, attributes) do
    struct
    |> cast(
      attributes,
      [:id, :name, :type, :room, :interface, :monitor_hold, :config],
      empty_values: ["", nil]
    )
    |> validate_required([:id, :type, :interface])
    |> HomeApp.Configuration.ensure_name()
  end
end
