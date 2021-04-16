defmodule HTTPNotifier do
  @content_types %{
    "plain" => "text/plain",
    "json" => "application/json"
  }

  @default_content_type "text/plain"

  def notify(
        %{} = notifier_config,
        %{} = action_config,
        %HomeApp.Event{subject: subject, data: event_data}
      ) do
    eex_bindings = bindings(subject, action_config, event_data)

    %HTTPoison.Request{
      method: Map.get(notifier_config, :method, "get"),
      url: EEx.eval_string(notifier_config.url, eex_bindings),
      body: EEx.eval_string(Map.get(notifier_config, :body, ""), eex_bindings),
      headers: headers(notifier_config)
    }
    |> IO.inspect(label: "HTTP request")
    |> HTTPoison.request()
    |> IO.inspect(label: "HTTP response")
  end

  defp bindings(subject, action_config, event_data) do
    (subject || %{})
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
