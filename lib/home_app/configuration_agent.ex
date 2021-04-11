defmodule HomeApp.ConfigurationAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn ->
      Application.get_env(:home_app, :yml_config)
      |> HomeApp.Configuration.load!()
      |> IO.inspect(label: "loaded configuration")
    end, name: __MODULE__)
  end

  def set_configuration(configuration) do
    Agent.update(__MODULE__, fn _state -> configuration end)
  end

  def get_configuration() do
    Agent.get(__MODULE__, fn configuration -> configuration end)
  end

  def name() do
    Agent.agent
  end
end
