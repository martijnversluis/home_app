defmodule Entsoe.Xml.EventHandler do
  @behaviour Saxy.Handler
  alias Entsoe.Document

  def handle_event(:start_document, _attributes, state), do: {:ok, state}

  def handle_event(:start_element, {"Publication_MarketDocument", _attributes}, _state) do
    {:ok, {%Document{}}}
  end

  def handle_event(:start_element, {"period.timeInterval", _attributes}, {%Document{} = document}) do
    {:ok, {document, :period}}
  end

  def handle_event(:start_element, {"Point", _attributes}, {%Document{} = document, :time_series}) do
    {:ok, {document, [:time_series, :point]}}
  end

  def handle_event(
        :start_element,
        {"timeInterval", _attributes},
        {%Document{} = document, :time_series}
      ) do
    {:ok, {document, [:time_series, :ignore]}}
  end

  def handle_event(:start_element, {"start", _attributes}, {%Document{} = document, :period}) do
    {:ok, {document, [:period, :start]}}
  end

  def handle_event(
        :start_element,
        {element_name, _attributes},
        {%Document{} = document, [step, :ignore]} = state
      )
      when element_name in ["start", "end"] do
    {:ok, {document, [step, :ignore]}}
  end

  def handle_event(:start_element, {"end", _attributes}, {%Document{} = document, :period}) do
    {:ok, {document, [:period, :end]}}
  end

  def handle_event(:characters, date_time_string, {%Document{} = document, [:period, :start]}) do
    {
      :ok,
      {
        document |> Map.put(:period_start, Timex.parse!(date_time_string, "{ISO:Extended:Z}")),
        :period
      }
    }
  end

  def handle_event(:characters, date_time_string, {%Document{} = document, [:period, :end]}) do
    {
      :ok,
      {
        document |> Map.put(:period_end, Timex.parse!(date_time_string, "{ISO:Extended:Z}")),
        :period
      }
    }
  end

  def handle_event(:start_element, {"TimeSeries", _attributes}, {%Document{} = document}) do
    {:ok, {document, :time_series}}
  end

  def handle_event(
        :start_element,
        {"position", _attributes},
        {%Document{} = document, [:time_series, :point]}
      ) do
    {:ok, {document, [:time_series, :point, :position]}}
  end

  def handle_event(
        :start_element,
        {"price.amount", _attributes},
        {%Document{} = document, [:time_series, :point], number}
      ) do
    {:ok, {document, [:time_series, :point, :price], number}}
  end

  def handle_event(
        :characters,
        position,
        {%Document{} = document, [:time_series, :point, :position]}
      ) do
    {number, _} = Integer.parse(position)

    {
      :ok,
      {document, [:time_series, :point], number}
    }
  end

  def handle_event(
        :characters,
        price_string,
        {%Document{} = document, [:time_series, :point, :price], position}
      ) do
    {price, _} = Float.parse(price_string)

    {
      :ok,
      {
        document
        |> Map.update(:prices, %{}, fn prices ->
          Map.put(prices, position, price)
        end),
        [:time_series, :point]
      }
    }
  end

  def handle_event(:end_element, "Point", {%Document{} = document, [:time_series, :point]}) do
    {
      :ok,
      {document, :time_series}
    }
  end

  def handle_event(:end_element, "period.timeInterval", {%Document{} = document, :period}) do
    {:ok, {document}}
  end

  def handle_event(:end_element, "timeInterval", {%Document{} = document, [step, :ignore]}) do
    {:ok, {document, step}}
  end

  def handle_event(:start_element, {element_name, _attributes}, state)
      when element_name in [
             "mRID",
             "revisionNumber",
             "type",
             "sender_MarketParticipant.mRID",
             "sender_MarketParticipant.marketRole.type",
             "receiver_MarketParticipant.mRID",
             "receiver_MarketParticipant.marketRole.type",
             "createdDateTime",
             "businessType",
             "in_Domain.mRID",
             "out_Domain.mRID",
             "currency_Unit.name",
             "price_Measure_Unit.name",
             "curveType",
             "Period",
             "resolution"
           ] do
    {:ok, state}
  end

  def handle_event(:end_element, _element_name, state), do: {:ok, state}
  def handle_event(:characters, characters, state), do: {:ok, state}
  def handle_event(:end_document, _, {%Document{} = document, _}), do: {:ok, document}
end
