defmodule Lists.Events.Metrics do


  @doc """
  Generates the following metrics for events in the provided list:

  - Total Events
  - Active Events
  - Events today
  - Overdue Events

  Data is based on data found in the meta data for each event. No evaluation is done on each event.
  """
  def generate_metrics lists do
    metrics = %{"Total Events" => 0, "Events Today" => 0, "Events Overdue" => 0}
    lists
      |> Enum.filter(&(DataServer.is_type(&1,"Event")))
      |> Enum.reduce(metrics,&event_metrics/2)
  end

  def event_metrics(record, state) do
    %{
      "Total Events" => state["Total Events"] + 1,
      "Active Events" => 0,
      "Events Today" => 0,
      "Events Overdue" => state["Events Overdue"] + is_positive(record["Eval Data"]["Overdue Count"])
    }
  end

  def is_positive value do
    cond do
      value > 0 -> 1
      true -> 0
    end
  end
end
