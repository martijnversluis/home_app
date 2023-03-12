defmodule HomeApp.Configuration.Interface do
  alias Ecto.Changeset
  use HomeApp.Configuration.Schema

  schema "" do
    field(:id, :string)
    field(:type, :string)
    field(:host, :string)
    field(:port, :integer, default: nil)
    field(:polling_interval, :integer, default: nil)
    field(:schedule, :string, default: nil)
    field(:config, HomeApp.Configuration.Config)
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [:id, :type, :host, :port, :polling_interval, :schedule, :config],
      empty_values: ["", nil]
    )
    |> validate_required([:id, :type])
    |> require_valid_polling_interval_or_schedule()
  end

  defp require_valid_polling_interval_or_schedule(changeset) do
    case {
      fetch_field!(changeset, :polling_interval),
      fetch_field!(changeset, :schedule)
    } do
      {nil, nil} ->
        changeset

      {_polling_interval, nil} ->
        validate_polling_interval(changeset)

      {nil, _schedule} ->
        validate_schedule(changeset)

      {_polling_interval, _schedule} ->
        add_error(
          changeset,
          :polling_interval,
          "Supply either polling_interval or schedule, not both"
        )
    end
  end

  defp validate_polling_interval(changeset) do
    validate_number(changeset, :polling_interval, greater_than: 0)
  end

  defp validate_schedule(changeset) do
    validate_change(changeset, :schedule, fn :schedule, schedule ->
      case Crontab.CronExpression.Parser.parse(schedule) do
        {:ok, _expression} -> []
        {:error, error} -> [{:schedule, "Invalid cron expression: #{error}"}]
      end
    end)
  end
end
