defmodule Lists.Access do

  # Writes the list data to the specified file.
  def write_lists_to_file (lists) do
    {:ok, file} = File.open Application.fetch_env!(:lists, :list_file), [:write]
    lists
      |> Enum.map(&(write_record file, &1))
    File.close (file)
  end

  defp write_record file, record do
    for { a, b } <- record do
      write_record = (a != "Meta Data" && a != "Eval Data")
#      is_meta_data = (a == "Meta Data")
      case write_record do
        true ->
          IO.binwrite file, a <> " :: " <> b <> "\n"
        false ->
          nil
      end
    end
    IO.binwrite file, "\n"
  end

# Reads the list file and creates a set of maps in a list. Each map holds a
# record from the file.
  def load_lists do
    data = File.read!(Application.fetch_env!(:lists, :list_file))
#    data = File.read!(path)
    load_data data
  end

  def load_data(data) do
#    date = Timex.Date.now(Timex.Timezone.local())
    data
      |> String.split("\n")               # Get list of lines.
#      |> String.strip("\r")
      |> Enum.drop_while(&(&1 == ""))             # Remove leading empty lines.
      |> Enum.reverse
      |> Enum.drop_while(&(&1 == ""))             # Remove trailing empty lines.
      |> Enum.reverse
      |> Enum.map(&(String.split &1, " :: "))     # Split each kv pair.
      |> Enum.map(&(set_atom(&1)))                # Set key, value into map.
      |> Enum.chunk_by(&(&1 == %{:delim => 0}))   # Group by record.
      |> Enum.filter(&(&1 != [%{:delim => 0}]))   # Remove delimiters.
      |> Enum.map(&(maps_to_map(&1)))             # Combine records maps.
      |> Enum.map(&(add_meta_data(&1)))
#      |> Enum.map(&(Lists.Events.overdue(&1,date)))
  end

  defp add_meta_data (record) do
    count = Agent.get_and_update(RecordCounter, fn(n) -> {n + 1, n + 1} end)
    meta_data = %{ "Record ID" => count }
    m = case record do
      %{ "Rule" => rule } ->
        Map.merge(meta_data, %{ "Type" => "Event", "Parsed Rule" => parse_rule(rule)})
      %{ "List Name" => _ } ->
        Map.merge(meta_data, %{ "Type" => "List"})
      %{ "Tag" => _ } ->
        Map.merge(meta_data, %{ "Type" => "Tag"})
      _ ->
        Map.merge(meta_data, %{ "Type" => "Unknown"})
    end
    m = if Map.has_key?(record,"Checked") do
      { :ok, date } = Timex.parse(record["Checked"], "{D}-{Mshort}-{YYYY}")
      date = Timex.date(date)
      Map.merge(m,%{"Checked" => date})
    else
      m
    end
    xrec = %{ "Meta Data" => m }
    updated_record = Map.merge(record,xrec)
#    IO.inspect updated_record
    updated_record
  end

  defp maps_to_map (list) do
    list
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
  end

  defp set_atom (pair) do
    case pair do
      [a, b] ->
        %{String.strip a => String.strip b}
      _ ->
        %{:delim => 0}
    end
  end

# Takes the rule string and changes it into a list of lists. For example:
#
#   "{ April Day 1 }, { November Day 1 }"
# becomes;
#
#   [["April","Day","1"],["November","Day","1"]]
  defp parse_rule(rule) do
    rule
      |> String.split(",")
      |> Enum.map(&(String.strip(&1)))
      |> Enum.map(&(String.slice(&1,1..-2)))  #Remove braces and spaces.
      |> Enum.map(&(String.strip(&1)))
      |> Enum.map(&(String.split(&1," ")))
  end

end
