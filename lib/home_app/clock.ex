defmodule HomeApp.Clock do
  use GenServer

  def start_link({_pub_sub_module, _event_name} = state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init({_pub_sub_module, _event_name} = state) do
    schedule_next_tick()
    {:ok, state}
  end

  def schedule_next_tick() do
    Timex.now()
    |> Timex.set([second: 0, microsecond: 0])
    |> Timex.shift(minutes: 1)
    |> Timex.diff(Timex.now(), :milliseconds)
    |> :timer.send_after(__MODULE__, :tick)
  end

  def handle_info(:tick, {pub_sub_module, event_name} = state) do
    Phoenix.PubSub.broadcast(
      pub_sub_module,
      event_name,
      {event_name, current_time()}
    )
    {:noreply, state}
  end

  defp current_time() do
    Timex.Timezone.convert(Timex.now(), Timex.Timezone.local())
  end
end
