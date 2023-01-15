defmodule HomeApp.Event do
  defstruct type: nil, subject: nil, data: %{}, time: nil

  def new(type), do: new(type, nil)
  def new(type, subject), do: new(type, subject, %{})

  def new(type, subject, data) do
    %__MODULE__{
      type: type,
      subject: subject,
      data: data,
      time: current_time()
    }
  end

  def broadcast(pub_sub_module, %__MODULE__{type: event_type} = event) do
    IO.inspect(event, label: "Broadcast event")
    Phoenix.PubSub.broadcast(pub_sub_module, event_type, event)
  end

  def subscribe(pub_sub_module, event_type) do
    Phoenix.PubSub.subscribe(pub_sub_module, event_type)
  end

  defp current_time() do
    Timex.Timezone.convert(Timex.now(), Timex.Timezone.local())
  end
end
