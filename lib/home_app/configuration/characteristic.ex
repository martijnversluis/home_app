defmodule HomeApp.Configuration.Characteristic do
  alias HomeApp.Configuration.Characteristic.{BinaryStates, BinaryValues, NumericRange}
  alias HomeApp.Definition.Characteristic.Types
  use HomeApp.Configuration.Schema

  @types ~w[boolean enum float location percentage string ]

  schema "" do
    field(:id, :string)
    field(:name, :string)
    field(:source, :string, default: nil)
    field(:unit, :string)
    field(:writable, :boolean, default: false)
    field(:type, :string)
    field(:decimals, :integer, default: nil)
    embeds_one(:range, NumericRange)
    embeds_one(:values, BinaryValues)
    embeds_one(:states, BinaryStates)
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :name, :source, :unit, :writable, :type, :decimals],
      empty_values: ["", nil]
    )
    |> cast_embed(:range)
    |> cast_embed(:values)
    |> cast_embed(:states)
    |> validate_required([:id])
    |> HomeApp.Configuration.ensure_name()
    |> validate_inclusion(:type, Types.all())
    |> validate_on(:type, Types.numeric(), fn changeset ->
      validate_required(changeset, :range)
    end)
    |> set_default_binary_attribute(:values, %{on: "on", off: "off"})
    |> set_default_binary_attribute(:states, %{on: "active", off: "inactive"})
    |> set_default_source()
  end

  defp set_default_binary_attribute(changeset, field, default_value) do
    case Ecto.Changeset.fetch_field!(changeset, :type) do
      "binary" ->
        case Ecto.Changeset.get_field(changeset, field) do
          %{on: _, off: _} -> changeset
          _ -> Ecto.Changeset.put_change(changeset, field, default_value)
        end

      _ ->
        changeset
    end
  end

  defp set_default_source(changeset) do
    case Ecto.Changeset.fetch_field!(changeset, :source) do
      nil ->
        id = Ecto.Changeset.fetch_field!(changeset, :id)
        Ecto.Changeset.put_change(changeset, :source, id)

      _ ->
        changeset
    end
  end
end
