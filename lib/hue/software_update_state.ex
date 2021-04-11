defmodule Hue.SoftwareUpdateState do
  defstruct state: nil, last_install: nil

  def parse(nil), do: nil

  def parse(%{"state" => state, "lastinstall" => last_install}) do
    %__MODULE__{
      state: state,
      last_install: DateTime.from_iso8601(last_install)
    }
  end
end
