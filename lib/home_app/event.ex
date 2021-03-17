defmodule HomeApp.Event do
  @device_state_changed "device:state_changed"

  defstruct type: nil, subject: nil, data: %{}

  def device_state_changed(subject, data) do
    %__MODULE__{
      type: @device_state_changed,
      subject: subject,
      data: data
    }
  end
end
