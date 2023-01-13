defmodule HomeApp.DeviceHoldMonitor do
  use GenServer
  alias HomeApp.Event

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    Event.subscribe(HomeApp.PubSub, "device:state_changed")
    {:ok, state}
  end

  def handle_info(
        %Event{
          type: "device:state_changed",
          subject: device_id,
          data: {
           _previous_state,
            %{on: true} = _new_state
          }
        },
        state
      ) do
        {:ok, timer_id} = :timer.send_interval(100, __MODULE__, {:broadcast_device_hold, device_id})
        {:noreply, Map.put(state, device_id, {timer_id, 1})}
  end

  def handle_info(
        %Event{
          type: "device:state_changed",
          subject: device_id,
          data: {
            _previous_state,
            %{on: false} = _new_state
          }
        },
        state
      ) do
    case Map.get(state, device_id) do
      nil ->
        {:noreply, state}
      {timer_id, hold_count} ->
        {:ok, :cancel} = :timer.cancel(timer_id)
        {:noreply, Map.delete(state, device_id)}
    end
  end

  def handle_info(%Event{}, state), do: {:noreply, state}

  def handle_info({:broadcast_device_hold, device_id}, state) do
    {timer_id, hold_count} = Map.get(state, device_id)
    Event.broadcast(HomeApp.PubSub, Event.new("device:hold", device_id, %{count: hold_count}))
    IO.puts "DEVICE HOLD FOR #{device_id}: #{hold_count}"
    new_state = Map.put(state, device_id, {timer_id, hold_count + 1})
    {:noreply, new_state}
  end
end
