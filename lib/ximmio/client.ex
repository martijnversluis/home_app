defmodule Ximmio.Client do
  alias Ximmio.{Address}

  @api_root "https://wasteapi.ximmio.com/api"

  def fetch_address(company_code, post_code, house_number) do
    %{
      companyCode: company_code,
      postCode: post_code,
      houseNumber: house_number
    }
    |> post("/FetchAdress")
    |> Map.fetch!("dataList")
    |> List.first()
    |> Address.parse()
  end

  def get_calendar(
        %{unique_id: unique_address_id, community: community},
        company_code,
        start_date,
        end_date
      ) do
    get_calendar(unique_address_id, community, company_code, start_date, end_date)
  end

  def get_calendar(unique_address_id, community, company_code, start_date, end_date) do
    %{
      community: community,
      companyCode: company_code,
      uniqueAddressID: unique_address_id,
      startDate: start_date,
      endDate: end_date
    }
    |> post("/GetCalendar")
    |> Map.fetch!("dataList")
    |> Map.new(fn %{"pickupDates" => pickup_dates, "_pickupTypeText" => pickup_type} ->
      {
        pickup_type,
        Enum.map(pickup_dates, fn date -> Timex.parse!(date, "{ISOdate}T{ISOtime}") end)
      }
    end)
  end

  defp post(%{} = body, path) when is_binary(path) do
    HTTPoison.post!(@api_root <> path, Jason.encode!(body), [{"Content-Type", "application/json"}])
    |> Map.fetch!(:body)
    |> Jason.decode!()
  end
end
