defmodule Hue.Client do
  use GenServer
  alias Hue.{Device, Light, Sensor, Session}

  defstruct host: nil, device_type: nil, username: nil

  @api_root "/api"

  def start_link(host, port) do
    Connection.start_link(__MODULE__, {host, port})
  end

  def init({host, port}) do
    {:ok, {host, port}}
  end

  def login(%Session{} = session, device_type) do
    case post(session, "", %{device_type: device_type}) do
      {:ok, %{"username" => username}} ->
        {:ok, session |> Map.merge(%{device_type: device_type, username: username})}
      {:error, %{"description" => description}} ->
        {:error, description}
    end
  end

  def login(host, username) when is_binary(host) and is_binary(username) do
    %Session{host: host, username: username}
  end

  def get_lights(%Session{username: username} = session) do
    session
    |> get("/#{username}/lights")
    |> Enum.map(fn {id, light} -> {id, Device.parse(light, id, Light.State)} end)
    |> Enum.into(%{})
  end

  def get_light(%Session{} = session, %{id: id}) do
    session
    |> get_light(id)
  end

  def get_light(%Session{username: username} = session, id) do
    session
    |> get("/#{username}/lights/#{id}")
    |> Device.parse(id, Light.State)
  end

  def update_light(%Session{} = session, %{id: id}, %Light.StateChange{} = state_change) do
    session
    |> update_light(id, state_change)
  end

  def update_light(%Session{username: username} = session, id, %Light.StateChange{} = state_change) do
    session
    |> put(
         "/#{username}/lights/#{id}/state",
         state_change
         |> Light.StateChange.translate_to_hue()
         |> remove_empty_values()
       )
  end

  def update_light(%Session{} = session, light_or_id, %{} = state_change) do
    session
    |> update_light(light_or_id, %Light.StateChange{} |> Map.merge(state_change))
  end

  def get_sensor(%Session{username: username} = session, id) do
    session
    |> get("/#{username}/sensors/#{id}")
    |> Device.parse(id, Sensor.Daylight.State)
  end

  defp get(%Session{} = session, path) when is_binary(path) do
    session
    |> request("get", path)
  end

  defp post(%Session{} = session, path, %{} = parameters) when is_binary(path) do
    session
    |> request("post", path, parameters)
  end

  defp put(%Session{} = session, path, %{} = parameters) when is_binary(path) do
    session
    |> request("put", path, parameters)
  end

  defp remove_empty_values(map) do
    map
    |> Enum.reject(fn {_key, value} -> value == nil end)
    |> Map.new()
  end

  defp request(%Session{host: host} = _session, method, path, %{} = parameters \\ %{}) when is_binary(path) do
    %HTTPoison.Request{
      method: method,
      url: "http://" <> host <> @api_root <> path,
      body: encode_parameters(parameters)
    }
    |> perform_request()
  end

  defp encode_parameters(%{} = parameters) do
    case Enum.any?(parameters) do
      true -> Jason.encode!(parameters)
      false -> ""
    end
  end

  defp perform_request(%HTTPoison.Request{} = request) do
    request
#    |> IO.inspect(label: "Hue request")
    |> HTTPoison.request()
#    |> IO.inspect(label: "Hue response")
    |> process_response()
  end

  defp process_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body |> Jason.decode!() |> process_response()
  end

  defp process_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  defp process_response(response) when is_list(response) do
    response |> List.first() |> process_response()
  end

  defp process_response(%{"success" => %{} = success_response}) do
    {:ok, success_response}
  end

  defp process_response(%{"error" => %{} = error_response}) do
    {:error, error_response}
  end

  defp process_response(%{} = response), do: response
end
