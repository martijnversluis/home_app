defmodule HomeApp.Configuration.SchemaHelpers do
  def validate_conditional(changeset, condition_fun, fun) when is_function(condition_fun, 1) do
    if condition_fun.(changeset) do
      fun.(changeset)
    else
      changeset
    end
  end

  def validate_on(changeset, field, value, fun) do
    validate_conditional(changeset, fn changeset -> Ecto.Changeset.get_field(changeset, field) === value end, fun)
  end
end
