defmodule HomeApp.Clock do
  use GenServer
  alias HomeApp.Event

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(state) do
    schedule_next_tick()
    {:ok, state}
  end

  def schedule_next_tick() do
    Timex.now()
    |> Timex.set(second: 0, microsecond: 0)
    |> Timex.shift(minutes: 1)
    |> Timex.diff(Timex.now(), :milliseconds)
    |> :timer.send_after(__MODULE__, :tick)
  end

  def handle_info(:tick, state) do
    Event.broadcast(HomeApp.PubSub, Event.new("clock:tick"))
    schedule_next_tick()
    {:noreply, state}
  end

  defp current_time() do
    Timex.Timezone.convert(Timex.now(), Timex.Timezone.local())
  end
end
