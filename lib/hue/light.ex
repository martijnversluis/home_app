defmodule Hue.Light do
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
      "swupdate" => software_update,
      "type" => type,
      "name" => name,
      "modelid" => model_id,
      "manufacturername" => manufacturer_name,
      "productname" => product_name,
      "capabilities" => capabilities,
      "config" => config,
      "uniqueid" => unique_id,
      "swversion" => software_version
    } = data,
    id
      ) do
    %__MODULE__{
      id: id,
      state: Hue.Light.State.parse(state),
      software_update: Hue.SoftwareUpdateState.parse(software_update),
      type: type,
      name: name,
      model_id: model_id,
      manufacturer_name: manufacturer_name,
      product_name: product_name,
      capabilities: capabilities,
      config: config,
      unique_id: unique_id,
      software_version: software_version,
      software_config_id: data["swconfigid"],
      product_id: data["productid"]
    }
  end
end
