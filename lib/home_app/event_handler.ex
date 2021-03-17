defmodule HomeApp.EventHandler do
  def handle_event(event) do
    HomeApp.ConfigurationAgent.get_configuration()
    |> Map.get(:automations, [])
    |> Enum.each(
         fn automation ->
           if should_trigger_automation?(automation, event) do
             HomeApp.Action.trigger(automation, event)
           end
         end
       )
  end

  defp should_trigger_automation?(
         %{
           event: "activated",
           subject: subject
         } = _automation,
         %{
           type: "device:state_changed",
           subject: %{
             characteristic_type: "binary",
             id: device_id
           },
           data: %{
             previous_state: false,
             new_state: true
           }
         } = _event
       ), do: subject == device_id

  defp should_trigger_automation?(
         %{
           event: "deactivated",
           subject: subject
         } = _automation,
         %{
           type: "device:state_changed",
           subject: %{
             characteristic_type: "binary",
             id: device_id
           },
           data: %{
             previous_state: true,
             new_state: false
           }
         } = _event
       ), do: subject == device_id

  defp should_trigger_automation?(automation, event) do
    IO.inspect(event, label: "Do not trigger #{automation.id} for")
    false
  end
end
