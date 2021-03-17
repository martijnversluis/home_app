defmodule HomeApp.Configuration.Schema do
  defmacro __using__([]) do
    quote do
      import HomeApp.Configuration.SchemaHelpers
      import Ecto.Changeset
      use Ecto.Schema
      @primary_key false
    end
  end
end
