defmodule CheapEnergy.Driver do
  use HomeApp.DeviceDriver

  defp get_device_value(
         %{config: %{token: token, provider: provider}} = _interface,
         devices,
         _state
       )
       when is_list(devices) do
    prices = day_ahead_prices(provider, token) |> parse_date_times() |> filter_past()

    Map.new(devices, fn %{id: id, config: %{} = config} ->
      {
        id,
        {:ok, get_cheap_prices(prices, config)}
      }
    end)
  end

  defp get_cheap_prices(prices, %{consecutive: true, hours: hours}) do
    end_index = Enum.count(prices) - hours

    Enum.map(0..end_index, fn index ->
      sum_price =
        prices
        |> Enum.slice(index, 3)
        |> Enum.map(fn {_date_time, price} -> price end)
        |> Enum.sum()

      mean_price = Float.round(sum_price / hours / 1000, 2)
      date_time = prices |> Enum.at(index) |> elem(0)
      {date_time, mean_price}
    end)
    |> Enum.min_by(fn {_date_time, mean_price} -> mean_price end)
    |> to_price_map(hours)
  end

  def to_price_map({date_time, mean_price}, hours) do
    %{
      active: price_active?(date_time, hours),
      date_time: Timex.format!(date_time, "{RFC3339}"),
      price: mean_price
    }
  end

  defp price_active?(start_date_time, hours) do
    end_date_time = Timex.add(start_date_time, Timex.Duration.from_hours(hours))
    Timex.between?(Timex.now(), start_date_time, end_date_time)
  end

  defp today(), do: Date.utc_today()
  defp tomorrow(), do: today() |> Date.add(1)

  defp day_ahead_prices("entsoe", token) do
    client = Entsoe.Client.new(token)
    day_ahead_prices(client, today()) ++ day_ahead_prices(client, tomorrow())
  end

  defp day_ahead_prices(%Entsoe.Client{} = client, date) do
    case Entsoe.Client.day_ahead_prices(client, date) do
      {:ok, document} -> extract_entsoe_date_times_with_prices(document)
      {:error, :prices_not_settled} -> %Entsoe.Document{}
    end
  end

  defp day_ahead_prices("tibber", token) do
    case Tibber.Client.new(token) |> Tibber.Client.prices() do
      {:ok, prices} -> prices
    end
  end

  defp extract_entsoe_date_times_with_prices(
         %{period_start: period_start, prices: prices} = _document
       ) do
    Enum.map(prices, fn {position, price} ->
      {
        Timex.add(period_start, Timex.Duration.from_hours(position - 1)),
        price
      }
    end)
  end

  defp parse_date_times(%{} = prices) do
    Map.new(prices, fn
      {%{} = date_time, price} ->
        {date_time, price}
      {date_time, price} ->
        {
          date_time
          |> IO.inspect(label: "parse date time")
          |> Timex.parse!("{RFC3339}"),
          price
        }
    end)
  end

  defp filter_past(%{} = prices) do
    Enum.map(prices, fn pair -> pair end)
    |> filter_past()
  end

  defp filter_past(prices) when is_list(prices) do
    now = Timex.now()
    Enum.reject(prices, fn {date_time, _price} -> date_time |> Timex.before?(now) end)
  end

  def name(%{interface: id, interface_type: type, config: %{provider: provider}} = _device_info),
    do: String.to_atom("#{__MODULE__}_#{type}_#{id}_#{provider}")

  def name(%{id: id, type: type, config: %{provider: provider}} = _interface),
    do: String.to_atom("#{__MODULE__}_#{type}_#{id}_#{provider}")
end
