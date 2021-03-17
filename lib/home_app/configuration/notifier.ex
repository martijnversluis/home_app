defmodule HomeApp.Configuration.Notifier do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:interface, :string)
    field(:config, HomeApp.Configuration.Config, default: %{})
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :interface, :config])
    |> validate_required([:id, :interface])
  end
end
