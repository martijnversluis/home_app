defmodule HomeApp.DeviceStateAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def set_device_state(device_id, new_state) do
    Agent.update(__MODULE__, fn states ->
      previous_state = Map.get(states, device_id)

      case previous_state do
        ^new_state -> states
        _ ->
          IO.inspect({previous_state, new_state}, label: "#{device_id} changed")
          Phoenix.PubSub.broadcast(
            HomeApp.PubSub,
            "device:state_changed",
            {"device:state_changed", device_id, {previous_state, new_state}}
          )
          Map.put(states, device_id, new_state)
      end
    end)
  end

  def get_device_state(device_id) do
    Agent.get(__MODULE__, fn states -> Map.get(states, device_id) end)
  end

  def name() do
    Agent.agent()
  end
end
