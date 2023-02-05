defmodule HomeApp.DeviceDriver do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      alias HomeApp.Configuration.{Interface, DeviceType, Device}
      use GenServer

      def monitor_module(), do: unquote(Keyword.get(opts, :monitor_with))

      def init(state) do
        {:ok, state}
      end

      defoverridable init: 1

      def start_link({interface}) do
        GenServer.start_link(__MODULE__, {interface}, name: name(interface))
      end

      def get_value(interface, device_info) do
        GenServer.call(name(interface), {:get_value, interface, device_info})
      end

      def handle_call({:get_value, interface, device_info}, _, state) do
        {:reply, get_device_value(interface, device_info, state), state}
      end

      defp name(%{interface: id, interface_type: type} = _device_info),
        do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

      defp name(%{id: id, type: type} = _interface),
        do: String.to_atom("#{__MODULE__}_#{type}_#{id}")
    end
  end
end
