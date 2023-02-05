defmodule HomeApp.Configuration.Action do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:action, :string)
    field(:target, :string)
    field(:config, HomeApp.Configuration.Config)
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:action, :target, :config])
    |> validate_required([:action, :target])
  end
end
