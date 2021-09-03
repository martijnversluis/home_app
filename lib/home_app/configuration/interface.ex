defmodule HomeApp.Configuration.Interface do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:type, :string)
    field(:host, :string)
    field(:port, :integer, default: nil)
    field(:polling_interval, :integer, default: 1000)
    field(:config, HomeApp.Configuration.Config, default: %{})
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :type, :host, :port, :polling_interval, :config],
      empty_values: ["", nil]
    )
    |> validate_required([:id, :type, :host])
  end
end
