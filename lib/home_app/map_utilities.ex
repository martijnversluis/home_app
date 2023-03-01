defmodule HomeApp.MapUtilities do
  def stringify_keys(%{} = map) do
    map
    |> strip_structs()
    |> Enum.map(fn {key, value} ->
      {"#{key}", stringify_keys(value)}
    end)
    |> Map.new()
  end

  def stringify_keys(values) when is_list(values) do
    Enum.map(values, fn value -> stringify_keys(value) end)
  end

  def stringify_keys(value), do: value

  defp strip_structs(list) when is_list(list) do
    Enum.map(list, &strip_structs/1)
  end

  defp strip_structs(%_{} = struct) do
    Map.from_struct(struct) |> Map.delete(:__meta__) |> strip_structs()
  end

  defp strip_structs(%{} = map) do
    Map.new(map, fn {key, value} -> {key, strip_structs(value)} end)
  end

  defp strip_structs(value), do: value
end
