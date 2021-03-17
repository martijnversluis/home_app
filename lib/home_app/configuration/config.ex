defmodule HomeApp.Configuration.Config do
  use Ecto.Type
  def type, do: :map
  def cast(nil), do: {:ok, %{}}
  def cast(%{} = config), do: {:ok, keys_to_atoms(config)}
  def cast(_), do: :error
  def dump(map), do: map
  def load(map), do: map

  defp keys_to_atoms(string_key_map) when is_map(string_key_map) do
    for {key, val} <- string_key_map, into: %{} do
      {String.to_atom(key), keys_to_atoms(val)}
    end
  end

  defp keys_to_atoms(value), do: value
end
