defmodule Lists.ListEntry do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/listentry.html.eex"), [:entry])

  def list_entry(date) do
    {:ok, events } = DataServer.evaluate_events date

    events
      |> Enum.map(&(create_entry_data(&1,date)))
      |> Enum.map(&(Lists.ListEntry.base(&1)))
  end

  def create_entry_data(record,date) do
    { :ok, check_date } = Timex.format(date, "{0D}-{Mshort}-{YYYY}")
    meta_data = record["Meta Data"]
    %{ "Name" => record["Name"],
       "Rule" => record["Rule"],
       "Record ID" => meta_data["Record ID"],
       "Check Date" => check_date,
       "Instance" => DataServer.get_lists_instance }
  end

end
