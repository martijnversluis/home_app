defmodule Hue.Device do
  defstruct id: nil,
            state: %{},
            software_update: nil,
            type: nil,
            name: nil,
            model_id: nil,
            manufacturer_name: nil,
            product_name: nil,
            capabilities: nil,
            config: nil,
            unique_id: nil,
            software_version: nil,
            software_config_id: nil,
            product_id: nil

  def parse(
    %{
      "state" => %{} = state,
      "type" => type,
      "name" => name,
      "modelid" => model_id,
      "manufacturername" => manufacturer_name,
      "config" => config,
      "swversion" => software_version
    } = data,
    id
      ) do
    %__MODULE__{
      id: id,
      state: state,
      software_update: Hue.SoftwareUpdateState.parse(data["swupdate"]),
      type: type,
      name: name,
      model_id: model_id,
      manufacturer_name: manufacturer_name,
      product_name: data["productname"],
      capabilities: data["capabilities"],
      config: config,
      unique_id: data["uniqueid"],
      software_version: software_version,
      software_config_id: data["swconfigid"],
      product_id: data["productid"]
    }
  end
end
