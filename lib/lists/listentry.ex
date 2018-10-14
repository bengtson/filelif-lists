defmodule Lists.ListEntry do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/listentry.html.eex"), [:entry])

  EEx.function_from_file(:def, :overdue, Path.expand("./templates/overdueentry.html.eex"), [
    :entry
  ])

  EEx.function_from_file(:def, :link, Path.expand("./templates/listlink.html.eex"), [:entry])

  def show_link(link) do
    case link do
      nil ->
        ""

      _ ->
        parse_link(link)
        Lists.ListEntry.link(parse_link(link))
    end
  end

  def parse_link(link) do
    parts =
      link
      |> String.trim("{")
      |> String.trim("}")
      |> String.trim(" ")
      |> String.split(",")
      |> Enum.map(&String.trim(&1, " "))
      |> Enum.map(&String.trim(&1, "\""))

    [link_name | [link_address | _]] = parts

    %{
      "Link Name" => link_name,
      "Link Address" => link_address
    }
  end

  def list_entry(date, overdue) do
    cond do
      overdue ->
        {:ok, events} = DataServer.get_list_type("Event")
        date = Timex.shift(date, days: -1)

        events
        |> Enum.filter(&filter_overdue(&1))
        |> Enum.map(&create_entry_data(&1, date))
        |> Enum.map(&Lists.ListEntry.overdue(&1))

      true ->
        {:ok, events} = DataServer.evaluate_events(date)

        events
        |> Enum.map(&create_entry_data(&1, date))
        |> Enum.map(&Lists.ListEntry.base(&1))
    end
  end

  def create_entry_data(record, date) do
    {:ok, check_date} = Timex.format(date, "{0D}-{Mshort}-{YYYY}")
    meta_data = record["Meta Data"]
    overdue_type = record["Eval Data"]["Overdue Type"]
    count = record["Eval Data"]["Overdue Count"]

    count_string =
      cond do
        overdue_type == :single_date ->
          Integer.to_string(count) <> " Days"

        overdue_type == :rules ->
          Integer.to_string(count) <> " Times"

        true ->
          ""
      end

    %{
      "Name" => record["Name"],
      "Link" => record["Link"],
      "Rule" => record["Rule"],
      "Record ID" => meta_data["Record ID"],
      "Check Date" => check_date,
      "Instance" => DataServer.get_lists_instance(),
      "Overdue String" => count_string
    }
  end

  def filter_overdue(record) do
    count = record["Eval Data"]["Overdue Count"]
    count > 0
  end
end
