defmodule HomeApp.Configuration.Automation do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:event, :string)
    field(:time, :string)
    field(:subject, :string)
    field(:characteristic, :string)
    field(:action, :string)
    field(:target, :string)
    field(:config, HomeApp.Configuration.Config, default: %{})
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :event, :time, :subject, :characteristic, :action, :target, :config])
    |> validate_required([:id, :event, :action, :target])
  end
end
