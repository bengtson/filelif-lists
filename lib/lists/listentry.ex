defmodule Lists.ListEntry do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/listentry.html.eex"), [:first])

  def listentry do

#    events = [
#      %{"Checked" => "03-Apr-2016", "Name" => "Midland Mortgage Payment"},
#      %{"Checked" => "12-May-2016", "Name" => "Write Lists Compendium"}
#    ]

#   {:ok, events } = DataServer.get_list_type "Event"
    {:ok, events } = DataServer.evaluate_events
#  IO.inspect events

    events |>
      Enum.map(&(Lists.ListEntry.base (&1)))

  end

end
