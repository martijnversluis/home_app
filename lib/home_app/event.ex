defmodule HomeApp.Event do
  @device_state_changed "device:state_changed"
  @clock_tick "clock:tick"

  defstruct type: nil, subject: nil, data: %{}

  def device_state_changed(subject, data) do
    %__MODULE__{
      type: @device_state_changed,
      subject: subject,
      data: data
    }
  end

  def clock_tick(data) do
    %__MODULE__{
      type: @clock_tick,
      data: data
    }
  end
end
