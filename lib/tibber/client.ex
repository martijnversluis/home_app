defmodule Tibber.Client do
  defstruct token: nil

  @api_root "https://api.tibber.com"

  def new(token), do: %__MODULE__{token: token}

  def prices(%__MODULE__{token: token}) do
    """
      {
        viewer {
          homes {
            currentSubscription{
              priceInfo{
                today {
                  total
                  startsAt
                }
                tomorrow {
                  total
                  startsAt
                }
              }
            }
          }
        }
      }
    """
    |> query(token)
    |> extract_prices()
    |> compress_prices()
    |> respond()
  end

  defp extract_prices(%{
        "data" => %{
          "viewer" => %{
            "homes" => [
              %{
                "currentSubscription" => %{
                  "priceInfo" => %{
                    "today" => today,
                    "tomorrow" => tomorrow
                  }
                }
              }
            ]
          }
        }
      }),
      do: today ++ tomorrow

  defp compress_prices(prices) when is_list(prices) do
    Map.new(prices, fn %{"startsAt" => starts_at, "total" => total} ->
      {
        Timex.parse!(starts_at, "{ISOdate}T{ISOtime}{Z:}") |> Timex.format!("{RFC3339}"),
        total * 1000
      }
    end)
  end

  defp respond(response), do: {:ok, response}

  defp query(query, token), do: post(%{query: query}, "/v1-beta/gql", token)

  defp post(body, path, token) when is_binary(path) do
    HTTPoison.post!(
      @api_root <> path,
      Jason.encode!(body),
      [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]
    )
    |> Map.fetch!(:body)
    |> decode_json!()
  end

  defp decode_json!(body) do
    {:ok, data} = decode_json(body)
    data
  end

  defp decode_json(body) do
    case Jason.decode(body) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, "#{error}\n\n#{body}"}
    end
  end
end
