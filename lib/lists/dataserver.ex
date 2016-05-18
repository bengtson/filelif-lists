defmodule DataServer do
  use GenServer
  @moduledoc """
  Provides UpNext database functions.

  All upnext data access should be through this module.
  """

  @doc """
  Starts the GenServer.
  """
  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [name: UpNextServer])
  end

  # Client code follows.

  @doc """
  Returns the full set of lists.
  """
  def get_lists do
      GenServer.call(UpNextServer, :get_lists)
  end

  @doc """
  Returns the types of records from the lists.
  """
  def get_list_type(type) do
    GenServer.call(UpNextServer, {:type, type})
  end

  @doc """
  Evaluates all event dates based on the date provdied.
  """
  def evaluate_events(eval_date \\ Timex.Date.now(Timex.Timezone.local())) do
    GenServer.call(UpNextServer, {:evaluate, eval_date})
  end

  @doc """
  Writes the full set of lists to the list file.
  """
  def write_lists do
      GenServer.call(UpNextServer, :write_lists)
  end

  def handle_call(:get_lists, _from, lists) do
    {:reply, lists, lists}
  end

  def handle_call({:type, type}, _from, lists) do
    typelist = lists
      |> Enum.filter(&(is_type(&1,type)))   # Remove unwanted type.
    {:reply, {:ok, typelist}, lists}
  end

  # Probably have a case statement that looks at record type. If not an event,
  # then return it. If it's an event, call the evaluate_event funciton.
  def handle_call({:evaluate, eval_date}, _from, lists) do
    lists
      |> Enum.map(&(find_events(&1,eval_date)))
    {:reply, {:ok}, lists}
  end

  def handle_call(:write_lists, _from, lists) do
    write_lists_to_file (lists)
    {:reply, :ok, lists}
  end

  def find_events(record,eval_date) do
    case record do
      %{ "Type" => "Event"} ->
        %{ "Rule" => rule } = record
        checked = Map.get(record,"Checked")
#        %{ "Checked" => checked } = record
        IO.inspect record
        IO.inspect rule
        IO.inspect checked
        record
      _ ->
        record
    end
  end

  def is_type(record, type) do
    case record do
      %{ "Type" => ^type } ->
        true
      _ ->
        false
    end
  end

  def init (:ok) do
    {:ok, load_lists}
  end

  # Writes the list data to the specified file.
  defp write_lists_to_file (lists) do
    {:ok, file} = File.open Application.fetch_env!(:lists, :test_file), [:write]
    lists
      |> Enum.map(&(write_record file, &1))
    File.close (file)
  end

  defp write_record file, record do
    for { a, b } <- record do
      IO.binwrite file, a <> " :: " <> b <> "\n"
    end
    IO.binwrite file, "\n"
  end

# Reads the list file and creates a set of maps in a list. Each map holds a
# record from the file.
  def load_lists do
    File.read!(Application.fetch_env!(:lists, :list_file))
      |> String.split("\n")               # Get list of lines.
      |> Enum.drop_while(&(&1 == ""))             # Remove leading empty lines.
      |> Enum.reverse
      |> Enum.drop_while(&(&1 == ""))             # Remove trailing empty lines.
      |> Enum.reverse
      |> Enum.map(&(String.split &1, " :: "))     # Split each kv pair.
      |> Enum.map(&(set_atom(&1)))                # Set key, value into map.
      |> Enum.chunk_by(&(&1 == %{:delim => 0}))   # Group by record.
      |> Enum.filter(&(&1 != [%{:delim => 0}]))   # Remove delimiters.
      |> Enum.map(&(maps_to_map(&1)))             # Combine records maps.
      |> Enum.map(&(add_type(&1)))                # Add record type.
  end

  defp maps_to_map (list) do
    list
      |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
  end

  defp set_atom (pair) do
    case pair do
      [a, b] ->
        %{a => b}
      _ ->
        %{:delim => 0}
    end
  end

# Attaches a record type field to each record. Also parses the rule String
# into a list of lists for easier handling.
  defp add_type record do
    case record do
      %{ "Rule" => rule } ->
        Map.merge(record, %{ "Type" => "Event", "Rule" => parse_rule(rule)})
      %{ "List Name" => _ } ->
        Map.merge(record, %{ "Type" => "List"})
      %{ "Tag" => _ } ->
        Map.merge(record, %{ "Type" => "Tag"})
      _ ->
        Map.merge(record, %{ "Type" => "Unknown"})
    end
  end

# Takes the rule string and changes it into a list of lists. For example:
#
#   "{ April Day 1 }, { November Day 1 }"
# becomes;
#
#   [["April","Day","1"],["November","Day","1"]]
  def parse_rule(rule) do
    rule
      |> String.split(",")
      |> Enum.map(&(String.strip(&1)))
      |> Enum.map(&(String.slice(&1,1..-2)))
      |> Enum.map(&(String.strip(&1)))
      |> Enum.map(&(String.split(&1," ")))
  end

end
