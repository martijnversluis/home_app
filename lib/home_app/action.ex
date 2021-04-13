defmodule HomeApp.Action do
  def trigger(
        %{action: "notify", target: notifier_id, config: action_config} = _automation,
        %HomeApp.Event{} = event
      ) do
    HomeApp.Notifier.notify(notifier_id, event, action_config)
  end

  def trigger(
        %{action: action, target: device_id} = _automation,
        %HomeApp.Event{} = _event
      )  when action in ["activate", "deactivate"] do
    HomeApp.ConfigurationAgent.get_configuration()
    |> HomeApp.Configuration.get_device_info(device_id)
    |> HomeApp.DeviceDriver.dispatch(action)
  end
end
