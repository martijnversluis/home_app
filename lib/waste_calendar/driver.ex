defmodule WasteCalendar.Driver do
  use HomeApp.DeviceDriver

  defp get_device_value(
         %{
           config: %{company_code: company_code}
         } = _interface,
         devices,
         _state
       )
       when is_list(devices) do
    Map.new(devices, fn %{id: id, config: %{post_code: post_code, house_number: house_number}} ->
      {
        id,
        {
          :ok,
          Ximmio.Client.fetch_address(company_code, post_code, house_number)
          |> Ximmio.Client.get_calendar(company_code, todays_date(), next_weeks_date())
          |> get_next_waste_collection()
        }
      }
    end)
  end

  defp get_next_waste_collection(%{} = dates) do
    dates
    |> Enum.map(fn {waste_type, dates} -> {waste_type, List.first(dates)} end)
    |> Enum.sort(fn {_waste_type_a, date_a}, {_waste_type_b, date_b} -> date_a > date_b end)
    |> List.first()
    |> build_result()
  end

  defp build_result({waste_type, date}) do
    %{
      active: date_is_active(date),
      waste_type: waste_type,
      date: date
    }
  end

  defp date_is_active(date) do
    Timex.diff(date, Timex.today(), :days) <= 1
  end

  defp todays_date(), do: date_string(0)
  def tomorrows_date(), do: date_string(1)
  defp next_weeks_date(), do: date_string(7)

  defp date_string(days_to_add) do
    Date.utc_today()
    |> Date.add(days_to_add)
    |> Date.to_string()
  end
end
