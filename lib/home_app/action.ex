defmodule HomeApp.Action do
  alias HomeApp.Event

  def trigger(%{actions: actions} = _automation, event) do
    Enum.map(actions, fn action -> trigger(action, event) end)
  end

  def trigger(
        %{action: "notify", target: notifier_id, config: action_config} = _automation_action,
        %Event{} = event
      ) do
    HomeApp.Notifier.notify(notifier_id, event, action_config)
  end

  def trigger(
        %{action: action, target: device_id} = _automation_action,
        %Event{} = _event
      )
      when action in ["activate", "deactivate", "blink"] do
    HomeApp.ConfigurationAgent.get_configuration()
    |> HomeApp.Configuration.get_device_info(device_id)
    |> HomeApp.DeviceControl.dispatch(action)
  end
end
