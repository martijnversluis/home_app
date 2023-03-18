defmodule HomeApp.DeviceStateAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def set_device_state(device_id, new_state) do
    Agent.update(__MODULE__, fn states ->
      Map.put(states, device_id, new_state)
    end)
  end

  def get_device_state(device_id) do
    Agent.get(__MODULE__, fn states -> Map.get(states, device_id) end)
  end

  def name(), do: __MODULE__
end
