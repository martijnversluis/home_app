defmodule HomeApp.Automator do
  use GenServer
  alias HomeApp.Event

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    Event.subscribe(HomeApp.PubSub, "device:state_changed")
    Event.subscribe(HomeApp.PubSub, "clock:tick")
    {:ok, {}}
  end

  def handle_info(%Event{} = event, socket) do
    handle_event(event)
    {:noreply, socket}
  end

  defp handle_event(event) do
    HomeApp.ConfigurationAgent.get_configuration()
    |> Map.get(:automations, [])
    |> Enum.each(fn automation ->
      if should_trigger_automation?(automation, event) do
        HomeApp.Action.trigger(automation, event)
      end
    end)
  end

  defp should_trigger_automation?(
         %{
           event: "time",
           value: automation_time
         } = _automation,
         %Event{
           type: "clock:tick",
           time: event_time
         } = _event
       ) do
    [automation_hours, automation_minutes] =
      automation_time
      |> String.split(":")
      |> Enum.map(fn part ->
        {num, _rest} = Integer.parse(part)
        num
      end)

    automation_hours == event_time.hour && automation_minutes == event_time.minute
  end

  defp should_trigger_automation?(
         %{} = _automation,
         %{
           type: "device:state_changed",
           data: %{previous_state: nil}
         } = _event
       ),
       do: false

  defp should_trigger_automation?(
         %{
           characteristic: characteristic_id,
           event: _automation_event,
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
        characteristic =
          Enum.find(characteristics, fn characteristic ->
            characteristic.source == characteristic_id
          end)

        previous_characteristic_state = Map.fetch!(previous_state, characteristic_id)
        new_characteristic_state = Map.fetch!(new_state, characteristic_id)

        should_trigger_device_state_changed_automation?(
          automation,
          characteristic,
          previous_characteristic_state,
          new_characteristic_state
        )

      _ ->
        false
    end
  end

  defp should_trigger_automation?(_automation, _event), do: false

  defp should_trigger_device_state_changed_automation?(
         %{event: "activated"} = _automation,
         %{type: "binary"} = _characteristic,
         false = _previous_state,
         true = _new_state
       ),
       do: true

  defp should_trigger_device_state_changed_automation?(
         %{event: "deactivated"} = _automation,
         %{type: "binary"} = _characteristic,
         true = _previous_state,
         false = _new_state
       ),
       do: true

  defp should_trigger_device_state_changed_automation?(
         %{event: "state", value: value} = _automation,
         %{type: "string"} = _characteristic,
         _previous_state,
         new_state
       ),
       do: value == "#{new_state}"

  defp should_trigger_device_state_changed_automation?(
         _automation,
         _characteristic,
         _previous_state,
         _new_state
       ),
       do: false
end
