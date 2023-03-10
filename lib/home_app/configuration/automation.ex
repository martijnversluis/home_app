defmodule HomeApp.Configuration.Automation do
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:event, :string)
    field(:value, :string)
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
    |> cast(stringify_value(attributes), [:id, :event, :value, :subject, :characteristic])
    |> cast_embed(:actions)
    |> validate_required([:id, :event])
  end

  defp stringify_value(%{"value" => value} = attributes) when is_integer(value) do
    Map.put(attributes, "value", "#{value}")
  end

  defp stringify_value(%{} = attributes), do: attributes
end
