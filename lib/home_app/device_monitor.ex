defmodule HomeApp.DeviceMonitor do
  alias HomeApp.{DeviceControl, Event, MapUtilities}
  use GenServer

  def child_spec({driver, %{id: interface_id, type: interface_type} = interface, devices}) do
    %{
      id: String.to_atom("#{__MODULE__}_#{interface_type}_#{interface_id}"),
      start: {__MODULE__, :start_link, [{driver, interface, devices}]}
    }
  end

  def start_link({driver, interface, devices}) do
    GenServer.start_link(__MODULE__, {driver, interface, devices}, name: name(interface))
  end

  def name(%{id: id, type: type} = _interface), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

  def init({driver, %{polling_interval: nil, schedule: nil} = interface, devices}) do
    init({driver, Map.put(interface, :polling_interval, 1000), devices})
  end

  def init({driver, %{schedule: schedule, polling_interval: nil} = interface, devices})
      when is_binary(schedule) do
    send(name(interface), :update)
    Event.subscribe(HomeApp.PubSub, "clock:tick")
    {:ok, {driver, interface, devices}}
  end

  def init({driver, %{schedule: nil, polling_interval: polling_interval} = interface, devices})
      when is_number(polling_interval) do
    process = name(interface)
    send(process, :update)
    :timer.send_interval(polling_interval, process, :update)
    {:ok, {driver, interface, devices}}
  end

  def update(pid) do
    GenServer.call(pid, :update)
  end

  def handle_info(:update, state), do: update_devices(state)

  def update_devices({_driver, interface, devices} = state) do
    for {device_id, response} <- DeviceControl.get_value(interface, devices) do
      case response do
        {:ok, value} ->
          Event.broadcast(
            HomeApp.PubSub,
            Event.new("device:state_reported", device_id, MapUtilities.stringify_keys(value))
          )

        {:error, description} ->
          IO.puts("Error getting value for #{device_id}: #{description}")
      end
    end

    {:noreply, state}
  end

  def handle_info(
        %Event{type: "clock:tick"} = event,
        {_driver, %{schedule: schedule} = interface, _devices} = state
      ) do
    if Event.matches_schedule?(event, schedule) do
      update_devices(state)
    end

    {:noreply, state}
  end
end
