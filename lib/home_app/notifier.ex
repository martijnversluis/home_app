defmodule HomeApp.Notifier do
  def notify(notifier_id, %HomeApp.Event{} = event, %{} = action_config) when is_binary(notifier_id) do
    notifier =
      HomeApp.ConfigurationAgent.get_configuration()
      |> Map.get(:notifiers)
      |> Enum.find(fn notifier -> notifier.id == notifier_id end)

    notify(notifier, event, action_config)
  end

  def notify(
        %{config: notifier_config, interface: interface} = _notifier,
        %HomeApp.Event{} = event,
        %{} = action_config) do
    get_notifier_interface!(interface).notify(notifier_config, action_config, event)
  end

  def get_notifier_interface(interface) do
    case Application.get_env(:home_app, :notifiers, []) |> Keyword.get(String.to_atom(interface)) do
      nil -> {:error, "No notifier configured for #{interface}"}
      notifier -> {:ok, notifier}
    end
  end

  def get_notifier_interface!(interface) do
    {:ok, driver} = get_notifier_interface(interface)
    driver
  end
end
