defmodule Entsoe.Client do
  defstruct security_token: nil

  @api_url "https://web-api.tp.entsoe.eu/api"

  def new(security_token) do
    %__MODULE__{
      security_token: security_token
    }
  end

  def day_ahead_prices(%__MODULE__{} = client, date) do
    date_time = Timex.to_datetime(date)

    day_start =
      date_time
      |> Timex.set(hour: 0, minute: 0)
      |> Timex.format!("{YYYY}{0M}{0D}{h24}{m}")

    day_end =
      date_time
      |> Timex.set(hour: 23, minute: 0)
      |> Timex.format!("{YYYY}{0M}{0D}{h24}{m}")

    client
    |> get(%{
      documentType: "A44",
      In_Domain: "10YNL----------L",
      Out_Domain: "10YNL----------L",
      periodStart: day_start,
      periodEnd: day_end
    })
  end

  defp get(%__MODULE__{security_token: security_token}, %{} = params) do
    %HTTPoison.Request{
      method: "get",
      url: @api_url,
      params: Map.put(params, :securityToken, security_token)
    }
    |> perform_request()
  end

  defp perform_request(%HTTPoison.Request{} = request) do
    request
    |> HTTPoison.request()
    |> process_response()
  end

  defp process_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    case Entsoe.Xml.Parser.parse(body) do
      {:ok, %Entsoe.Document{} = document} -> {:ok, document}

      {
        :error,
        %{
          reason: {
            :bad_return,
            {
              :start_element, {:error, error}
            }
          }
        }
      } -> {:error, error}

      {:error, error} -> {:error, error}
    end
  end

  defp process_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end
end
