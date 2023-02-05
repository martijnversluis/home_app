defmodule Smoov.Client do
  alias Smoov.ChargePoint

  @api_root "https://www.smoovapp.eu/api"

  def get_charge_point(charge_point_id) when is_binary(charge_point_id) do
    get("/feature/experienceaccelerator/areas/chargepointmap/getchargepoints/#{charge_point_id}")
    |> ChargePoint.parse()
  end

  defp get(path) when is_binary(path), do: request("get", path)

  defp request(method, path) when is_binary(path) do
    %HTTPoison.Request{
      method: method,
      url: @api_root <> path,
      headers: [
        {"Accept", "*/*"},
        {"Accept-Language", "en-US,en;q=0.9"},
        {"Connection", "keep-alive"},
        {"Cookie",
         "ASP.NET_SessionId=psgybzddouxhqhcveddldknz; __RequestVerificationToken=c731kPEOTLmmOFV9HTK56udelrgKepw-RkiOdPGmLp6dcneDl-r-MRxiJLBh-rq4EbMU3KLGona6RTIC8VU65VZQKbglovofH4vcI7psrV41; sxa_site=Smoov; smoov#lang=en; ARRAffinity=c8bdcf711a676ed2e77de706f6b5cdee0da5544f46c62022f57fa94ba41e2089; ARRAffinitySameSite=c8bdcf711a676ed2e77de706f6b5cdee0da5544f46c62022f57fa94ba41e2089; SC_ANALYTICS_GLOBAL_COOKIE=ecc7e356ea234ce389b9705125eafe19|False; SC_sxa_analytics=ecc7e356ea234ce389b9705125eafe19|False"},
        {"DNT", "1"},
        {"Host", "www.smoovapp.eu"},
        {"Sec-Fetch-Dest", "empty"},
        {"Sec-Fetch-Mode", "cors"},
        {"Sec-Fetch-Site", "same-origin"},
        {"Sec-GPC", "1"},
        {"User-Agent",
         "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"},
        {"X-Requested-With", "XMLHttpRequest"}
      ]
    }
    |> perform_request()
  end

  defp perform_request(%HTTPoison.Request{} = request) do
    request
    |> HTTPoison.request()
    |> process_response()
  end

  defp process_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body
    |> Jason.decode!()
    |> process_response()
  end

  defp process_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  defp process_response(%{} = response), do: response
end
