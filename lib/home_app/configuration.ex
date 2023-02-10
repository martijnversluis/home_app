defmodule HomeApp.Configuration do
  alias HomeApp.Configuration.{
    Automation,
    Device,
    DeviceType,
    Group,
    Interface,
    Notifier,
    Room
  }

  import Ecto.Changeset
  use Ecto.Schema

  schema "configuration" do
    embeds_many(:rooms, Room)
    embeds_many(:interfaces, Interface)
    embeds_many(:device_types, DeviceType)
    embeds_many(:devices, Device)
    embeds_many(:notifiers, Notifier)
    embeds_many(:automations, Automation)
    embeds_many(:groups, Group)
  end

  def changeset(struct, attributes) do
    struct
    |> cast(attributes, [])
    |> cast_embed(:rooms)
    |> cast_embed(:interfaces)
    |> cast_embed(:device_types)
    |> cast_embed(:devices)
    |> cast_embed(:notifiers)
    |> cast_embed(:automations)
    |> cast_embed(:groups)
    |> validate_ids(:devices, :type, :device_types)
    |> validate_ids(:devices, :room, :rooms)
    |> validate_ids(:devices, :interface, :interfaces)
    |> validate_ids(:groups, :devices, :devices)
  end

  def load!(filename) do
    case File.read(filename) do
      {:ok, yaml} ->
        yaml
        |> YAML.Parser.parse!()
        |> keys_to_atoms()
        |> merge_driver_info()
        |> strip_structs()
        |> parse!()

      {:error, error} ->
        {:error, "Could not read config file: #{error}"}
    end
  end

  def parse(attributes) do
    case struct(__MODULE__) |> changeset(attributes) do
      %{valid?: true} = changeset ->
        {:ok, apply_changes(changeset)}

      changeset ->
        {:error, changeset_error_to_string(changeset)}
    end
  end

  def changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> IO.inspect(label: "traversed errors")
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc}#{k}: #{joined_errors}\n"
    end)
  end

  def parse!(attributes) do
    {:ok, configuration} = parse(attributes)
    configuration
  end

  def ensure_name(changeset) do
    put_change(changeset, :name, get_name(changeset))
  end

  def get_device_info(configuration, device_ids) when is_list(device_ids) do
    Enum.map(device_ids, fn device_id -> get_device_info(configuration, device_id) end)
  end

  def get_device_info(configuration, %{id: device_id} = _device),
    do: get_device_info(configuration, device_id)

  def get_device_info(configuration, device_id) do
    case get_group(configuration, device_id) do
      %{devices: device_ids} ->
        get_device_info(configuration, device_ids)

      nil ->
        device = get_device(configuration, device_id)
        device_type = get_device_type(configuration, device.type)
        interface = get_interface(configuration, device.interface)

        %{
          id: device_id,
          type: "device",
          interface: device.interface,
          interface_type: interface.type,
          host: interface.host,
          port: interface.port,
          config: Map.merge(device.config, interface.config),
          device_type: device_type,
          characteristic_ids:
            device_type.characteristics |> Enum.map(fn characteristic -> characteristic.id end)
        }
    end
  end

  def get_interfaces_with_devices(%{devices: devices, interfaces: interfaces} = _configuration) do
    interfaces
    |> Enum.map(fn %{id: interface_id} = interface ->
      {
        interface,
        Enum.filter(devices, fn %{interface: device_interface} = _device ->
          device_interface == interface_id
        end)
      }
    end)
  end

  def get_characteristics(configuration, characteristic_ids) do
    Enum.map(characteristic_ids, fn characteristic_id ->
      get_characteristic(configuration, characteristic_id)
    end)
  end

  def get_characteristic(configuration, characteristic_id),
    do: find(configuration, :characteristics, characteristic_id)

  def get_device(configuration, device_id) do
    find(configuration, :devices, device_id)
    |> Map.update(:config, %{}, fn
      %{} = config -> config
      _ -> %{}
    end)
  end

  def get_device_type(configuration, device_type),
    do: find(configuration, :device_types, device_type)

  def get_interface(configuration, interface_id) do
    find(configuration, :interfaces, interface_id)
    |> Map.update(:config, %{}, fn
      %{} = config -> config
      _ -> %{}
    end)
  end

  def get_room(configuration, room_id), do: find(configuration, :rooms, room_id)
  def get_group(configuration, group_id), do: find(configuration, :groups, group_id)

  defp keys_to_atoms(%{} = map) do
    Map.new(map, fn {key, value} -> {String.to_existing_atom(key), value} end)
  end

  defp merge_driver_info(configuration) do
    Map.merge(configuration, driver_info())
  end

  defp driver_info() do
    Application.get_env(:home_app, :device_drivers, [])
    |> Enum.reduce(
      %{device_types: []},
      fn {driver_name, driver}, %{device_types: device_types} = _acc ->
        [namespace, "Driver"] = Module.split(driver)
        definition = Module.concat([namespace, Definition])

        driver_device_types =
          definition.device_types()
          |> Enum.map(fn {id, %{} = device_type} ->
            device_type
            |> Map.put(:id, "#{driver_name}_#{id}")
            |> characteristics_map_to_list()
            |> IO.inspect(label: "device_type")
          end)

        %{device_types: device_types ++ driver_device_types}
      end
    )
  end

  defp characteristics_map_to_list(%{characteristics: %{} = characteristics} = device_type) do
    Map.put(
      device_type,
      :characteristics,
      Enum.map(characteristics, fn {id, characteristic} ->
        Map.put(characteristic, :id, "#{id}")
      end)
    )
  end

  defp find(configuration, collection, id) do
    configuration
    |> Map.fetch!(collection)
    |> Enum.find(fn item -> item.id == id end)
  end

  defp get_name(changeset) do
    id = fetch_field!(changeset, :id)

    case get_field(changeset, :name) do
      empty when empty in [nil, ""] ->
        case get_field(changeset, :room, "") do
          "" -> id
          room -> String.replace_leading(id, "#{room}_", "")
        end
        |> Phoenix.Naming.humanize()

      name ->
        name
    end
  end

  defp validate_ids(changeset, relation, foreign_key, referred_relation) do
    validate_change(changeset, relation, fn ^relation, items ->
      valid_ids =
        changeset
        |> fetch_field!(referred_relation)
        |> Enum.map(fn item -> Map.fetch!(item, :id) end)

      invalid_referred_ids =
        items
        |> Enum.map(fn item -> fetch_field!(item, foreign_key) end)
        |> List.flatten()
        |> IO.inspect(label: "#{foreign_key} values")
        |> Enum.uniq()
        |> Enum.reject(fn id -> Enum.member?(valid_ids, id) end)

      case Enum.any?(invalid_referred_ids) do
        true ->
          message =
            "Invalid #{relation} #{foreign_key} values: " <> Enum.join(invalid_referred_ids, ", ")

          [{relation, message}]

        false ->
          []
      end
    end)
  end

  defp strip_structs(list) when is_list(list) do
    Enum.map(list, &strip_structs/1)
  end

  defp strip_structs(%_{} = struct) do
    Map.from_struct(struct) |> Map.delete(:__meta__) |> strip_structs()
  end

  defp strip_structs(%{} = map) do
    Map.new(map, fn {key, value} -> {key, strip_structs(value)} end)
  end

  defp strip_structs(value), do: value
end
