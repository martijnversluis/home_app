defmodule HTTPNotifier do
  @content_types %{
    "plain" => "text/plain",
    "json" => "application/json"
  }

  @default_content_type "text/plain"

  def notify(
        %{} = notifier_config,
        %{} = action_config,
        %HomeApp.Event{subject: device_info, data: event_data}
      ) do
    %HTTPoison.Request{
      method: Map.get(notifier_config, :method, "get"),
      url: notifier_config.url,
      body: compile_body(notifier_config, bindings(device_info, action_config, event_data)),
      headers: headers(notifier_config)
    }
    |> IO.inspect(label: "HTTP request")
    |> HTTPoison.request()
    |> IO.inspect(label: "HTTP response")
  end

  defp compile_body(interface_config, bindings) do
    Map.get(interface_config, :body, "")
    |> EEx.eval_string(bindings)
  end

  defp bindings(device_info, action_config, event_data) do
    device_info
    |> Map.merge(action_config)
    |> Map.merge(event_data)
    |> Map.to_list()
  end

  defp headers(%{} = interface_config) do
    [
      {"Content-Type", content_type(interface_config)}
    ]
  end

  defp content_type(%{} = interface_config) do
    content_type = Map.get(interface_config, :content_type, "plain")
    Map.get(@content_types, content_type, @default_content_type)
  end
end
