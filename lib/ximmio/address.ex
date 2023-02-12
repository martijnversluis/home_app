defmodule Ximmio.Address do
  defstruct unique_id: nil,
            street: nil,
            house_number: nil,
            zip_code: nil,
            city: nil,
            community: nil

  def parse(
        %{
          "UniqueId" => unique_id,
          "Street" => street,
          "ZipCode" => zip_code,
          "City" => city,
          "Community" => community
        } = data
      ) do
    %__MODULE__{
      unique_id: unique_id,
      street: street,
      house_number: get_full_house_number(data),
      zip_code: zip_code,
      city: city,
      community: community
    }
  end

  defp get_full_house_number(%{
         "HouseNumber" => house_number,
         "HouseLetter" => house_letter,
         "HouseNumberIndication" => house_number_indication,
         "HouseNumberAddition" => house_number_addition
       }) do
    [
      house_number,
      house_letter,
      house_number_indication,
      house_number_addition
    ]
    |> Enum.filter(fn
      nil -> false
      "" -> false
      str -> str
    end)
    |> Enum.join("")
  end
end
