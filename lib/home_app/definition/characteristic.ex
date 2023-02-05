defmodule HomeApp.Definition.Characteristic do
  defstruct type: nil, writable: false, range: nil, enum_values: nil

  defmodule Types do
    @boolean "boolean"
    @enum "enum"
    @location "location"
    @numeric "numeric"
    @percentage "percentage"
    @string "string"

    def boolean, do: @boolean
    def enum, do: @enum
    def location, do: @location
    def numeric, do: @numeric
    def percentage, do: @percentage
    def string, do: @string

    def all() do
      [boolean(), enum(), location(), numeric(), percentage(), string()]
    end
  end

  def location(opts \\ []), do: new(Types.location(), opts)
  def string(opts \\ []), do: new(Types.string(), opts)
  def percentage(opts \\ []), do: new(Types.percentage(), opts)
  def boolean(opts \\ []), do: new(Types.boolean(), opts)
  def enum(values, opts \\ []), do: new(Types.enum(), opts |> Keyword.put(:enum_values, values))
  def numeric(opts \\ []), do: new(Types.numeric(), opts)

  def new(type, opts \\ []) do
    options =
      [writable: false, enum_values: nil]
      |> Keyword.merge(opts)

    %__MODULE__{
      type: type,
      writable: options[:writable],
      range: options |> Keyword.get(:range) |> format_range(),
      enum_values: options[:enum_values]
    }
  end

  defp format_range(min..max), do: %{min: min, max: max}
  defp format_range(range), do: range
end
