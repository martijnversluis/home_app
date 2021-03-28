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
         %{} = _automation,
         %{
           type: "device:state_changed",
           data: %{previous_state: nil}
         } = _event
       ), do: false

  defp should_trigger_automation?(
         %{
           characteristic: characteristic_id,
           event: event,
           subject: subject
         } = automation,
         %{
           subject: %{
             characteristics: characteristics,
             id: device_id
           },
           type: "device:state_changed",
           data: %{
             previous_state: previous_state,
             new_state: new_state
           }
         } = _event
       ) do
    case device_id do
      ^subject ->
        characteristic = Enum.find(characteristics, fn characteristic -> characteristic.source == characteristic_id end)
        previous_characteristic_state = Map.fetch!(previous_state, characteristic_id)
        new_characteristic_state = Map.fetch!(new_state, characteristic_id)

        should_trigger_device_state_changed_automation?(
          event,
          characteristic,
          previous_characteristic_state,
          new_characteristic_state
        )
      _ ->
        IO.puts("#{device_id} is not #{subject}")
        false
    end
  end

  defp should_trigger_automation?(automation, event) do
    IO.inspect({automation, event}, label: "Do not trigger #{automation.id} for")
    false
  end

  defp should_trigger_device_state_changed_automation?(
         "activated" = _event,
         %{type: "binary"} = _characteristic,
         false = _previous_state,
         true = _new_state
       ), do: true

  defp should_trigger_device_state_changed_automation?(
         "deactivated" = _event,
         %{type: "binary"} = _characteristic,
         true = _previous_state,
         false = _new_state
       ), do: true

  defp should_trigger_device_state_changed_automation?(_event, _characteristic, _previous_state, _new_state), do: false
end
