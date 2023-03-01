defmodule HomeApp.Definition.Characteristic do
  defstruct type: nil, writable: false, range: nil, enum_values: nil, currency: nil

  defmodule Types do
    @boolean "boolean"
    @date "date"
    @date_time "date_time"
    @enum "enum"
    @location "location"
    @money "money"
    @numeric "numeric"
    @percentage "percentage"
    @string "string"

    def boolean, do: @boolean
    def date, do: @date
    def date_time, do: @date_time
    def enum, do: @enum
    def location, do: @location
    def money, do: @money
    def numeric, do: @numeric
    def percentage, do: @percentage
    def string, do: @string

    def all() do
      [boolean(), date(), date_time(), enum(), location(), money(), numeric(), percentage(), string()]
    end
  end

  def boolean(opts \\ []), do: new(Types.boolean(), opts)
  def date(opts \\ []), do: new(Types.date(), opts)
  def date_time(opts \\ []), do: new(Types.date_time(), opts)

  def enum(values, opts \\ []) do
    new(
      Types.enum(),
      opts |> Keyword.put(:enum_values, values)
    )
  end

  def location(opts \\ []), do: new(Types.location(), opts)

  def money(currency, opts \\ []) do
    new(
      Types.money(),
      opts |> Keyword.put(:currency, currency)
    )
  end

  def numeric(opts \\ []), do: new(Types.numeric(), opts)
  def percentage(opts \\ []), do: new(Types.percentage(), opts)
  def string(opts \\ []), do: new(Types.string(), opts)

  def new(type, opts \\ []) do
    options =
      [writable: false, enum_values: nil, currency: nil]
      |> Keyword.merge(opts)

    %__MODULE__{
      type: type,
      writable: options[:writable],
      range: options |> Keyword.get(:range) |> format_range(),
      enum_values: options[:enum_values],
      currency: options[:currency]
    }
  end

  defp format_range(min..max), do: %{min: min, max: max}
  defp format_range(range), do: range
end
