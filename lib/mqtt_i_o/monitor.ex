defmodule MqttIO.Monitor do
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

  def init({driver, %{host: host, port: port, config: %{topic: topic}} = interface, devices}) do
    Tortoise.Supervisor.start_child(
      client_id: "homeapp_#{name(interface)}",
      handler: {MqttIO.Driver, [interface, devices]},
      server: {
        Tortoise.Transport.Tcp,
        host: host, port: port
      },
      subscriptions: [{topic, 0}]
    )

    {:ok, {driver, interface, devices}}
  end

  defp name(%{id: id, type: type} = _interface), do: String.to_atom("#{__MODULE__}_#{type}_#{id}")
end
