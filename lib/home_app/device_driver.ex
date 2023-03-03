defmodule HomeApp.DeviceDriver do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      alias HomeApp.{MapUtilities}
      alias HomeApp.Configuration.{Interface, DeviceType, Device}
      use GenServer

      def monitor_module(), do: unquote(Keyword.get(opts, :monitor_with))

      def init(state) do
        {:ok, state}
      end

      defoverridable init: 1

      def get_device_value(_interface, _device_info, _state), do: %{}
      defoverridable get_device_value: 3

      def start_link({interface}) do
        GenServer.start_link(__MODULE__, {interface}, name: name(interface))
      end

      def get_value(interface, device_info) do
        GenServer.call(name(interface), {:get_value, interface, device_info})
      end

      defoverridable get_value: 2

      def handle_call({:get_value, interface, device_info}, _, state) do
        {:reply, get_device_value(interface, device_info, state), state}
      end

      defp name(%{interface: id, interface_type: type} = _device_info),
        do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

      defp name(%{id: id, type: type} = _interface),
        do: String.to_atom("#{__MODULE__}_#{type}_#{id}")

      def stringify_keys(value), do: MapUtilities.stringify_keys(value)
      def strip_structs(value), do: MapUtilities.strip_structs(value)
    end
  end
end
