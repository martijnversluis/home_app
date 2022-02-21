defmodule HomeApp.DeviceHoldMonitor do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    Phoenix.PubSub.subscribe(HomeApp.PubSub, "device:state_changed")
    {:ok, state}
  end

  def handle_info(
        {
          "device:state_changed",
          device_id,
          {
            %{"on" => false} = _previous_state,
            %{"on" => true} = _new_state
          }
        },
        monitored_device_ids
      ) do
    case HomeApp.Configuration.get_device(device_id) do
      %{monitor_hold: true} ->
        timer = :timer.send_after(100, __MODULE__, {:broadcast_device_hold, device_id})
        {:noreply, Map.put(monitored_device_ids, device_id, timer)}
      _ ->
        {:noreply, monitored_device_ids}
    end
  end

  def handle_info(
        {
          "device:state_changed",
          device_id,
          {
            %{"on" => true} = _previous_state,
            %{"on" => false} = _new_state
          }
        },
        monitored_device_ids
      ) do
    monitored_device_ids
    |> Map.get(device_id)
    |> :timer.cancel()

    {:noreply, MapSet.delete(monitored_device_ids, device_id)}
  end

  def handle_info({:broadcast_device_hold, device_id}, monitored_device_ids) do
    Phoenix.PubSub.broadcast(
      HomeApp.PubSub,
      "device:hold",
      {"device:hold", device_id}
    )

    {:noreply, monitored_device_ids}
  end

  def handle_info(_message, state), do: {:noreply, state}
end
