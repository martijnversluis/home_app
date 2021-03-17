defmodule HomeApp.EventMonitor do
  use GenServer
  alias HomeApp.Event

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    {:ok, {Phoenix.PubSub.subscribe(HomeApp.PubSub, "device:state_changed")}}
  end

  def handle_info({"device:state_changed", device_id, {previous_state, new_state}}, socket) do
    HomeApp.ConfigurationAgent.get_configuration()
    |> HomeApp.Configuration.get_device_info(device_id)
    |> Event.device_state_changed(%{previous_state: previous_state, new_state: new_state})
    |> HomeApp.EventHandler.handle_event()

    {:noreply, socket}
  end

  def handle_info({:ssl_closed, ssl_connection}, socket) do
    IO.inspect(ssl_connection, label: "SSL connection closed:")
    {:noreply, socket}
  end
end
