defmodule HomeApp.Configuration.Automation do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:event, :string)
    field(:time, :string)
    field(:subject, :string)
    field(:characteristic, :string)
    embeds_many(:actions, HomeApp.Configuration.Action)
  end

  def changeset(struct, %{"action" => action, "target" => target} = attributes) do
    changeset(
      struct,
      attributes
      |> Map.drop(["action", "target", "config"])
      |> Map.put(
        "actions",
        [
          %{"action" => action, "target" => target, "config" => attributes["config"]}
        ]
      )
    )
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :event, :time, :subject, :characteristic])
    |> cast_embed(:actions)
    |> validate_required([:id, :event])
  end
end
