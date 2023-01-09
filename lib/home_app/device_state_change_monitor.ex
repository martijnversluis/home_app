defmodule HomeApp.DeviceStateChangeMonitor do
  use GenServer
  alias HomeApp.{DeviceStateAgent, Event}

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    Event.subscribe(HomeApp.PubSub, "device:state_reported")
    {:ok, {}}
  end

  def handle_info(%Event{type: "device:state_reported", subject: device_id, data: new_state}, socket) do
    previous_state = DeviceStateAgent.get_device_state(device_id)

    case previous_state do
      ^new_state ->
        IO.inspect(new_state, label: "state for #{device_id} unchanged")
      _ ->
        IO.inspect(new_state, label: "state for #{device_id} CHANGED")
        DeviceStateAgent.set_device_state(device_id, new_state)
        Event.broadcast(HomeApp.PubSub, Event.new("device:state_changed", device_id, {previous_state, new_state}))
    end

    {:noreply, socket}
  end

  def handle_info({:ssl_closed, ssl_connection}, socket) do
    IO.inspect(ssl_connection, label: "SSL connection closed:")
    {:noreply, socket}
  end
end
