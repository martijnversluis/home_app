defmodule Smoov.Monitor do
  use GenServer
  alias HomeApp.Event

  def child_spec() do
    %{
      id: String.to_atom("#{__MODULE__}"),
      start: {__MODULE__, :start_link, []}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init({pub_sub, interval_in_seconds, charge_point_ids}) when is_list(charge_point_ids) do
    fetch_charge_points(pub_sub, charge_point_ids)
    {:ok, timer_id} = :timer.send_interval(interval_in_seconds, __MODULE__, :fetch_charge_points)
    {:ok, {pub_sub, charge_point_ids, timer_id}}
  end

  def handle_info(:fetch_charge_points, {pub_sub, charge_point_ids, _timer_id} = state) do
    fetch_charge_points(pub_sub, charge_point_ids)
    {:noreply, state}
  end

  defp fetch_charge_points(pub_sub, charge_point_ids) do
    Enum.each(charge_point_ids, fn charge_point_id ->
      charge_point = Smoov.Client.get_charge_point(charge_point_id)
      Event.broadcast(pub_sub, Event.new("device:state_reported", charge_point_id, charge_point))
    end)
  end
end
