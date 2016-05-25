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
  Sets the state of the specified event to 'checked'
  """
  def check(record_id) do
    GenServer.call(UpNextServer, {:check, record_id})
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

  # Pattern match to get the record of interest.
  def handle_call({:check, record_id}, _from, lists) do
    IO.puts "Checking Record ID"
    updated_lists = lists
      |> Enum.map(&(check_record(&1,record_id)))
    {:reply, :ok, updated_lists}
  end

  def check_record(record, id) do
    { num_id, _ } = Integer.parse(id)
    %{ "!Record ID" => record_id } = record
    case record_id == num_id do
      true ->
        date = Timex.Date.now(Timex.Timezone.local())
        Map.merge(record, %{ "Checked" => "Yes" })
      false ->
        record
    end
  end

  # Probably have a case statement that looks at record type. If not an event,
  # then return it. If it's an event, call the evaluate_event funciton.
  def handle_call({:evaluate, eval_date}, _from, lists) do
    events = lists
      |> Enum.filter(&(is_type(&1,"Event")))
      |> Enum.filter(&(event_matches?(&1,eval_date)))
    {:reply, {:ok, events}, lists}
  end

  def handle_call(:write_lists, _from, lists) do
    write_lists_to_file (lists)
    {:reply, :ok, lists}
  end

  @doc """
  Checks the provided event record to see if it is active for the evalute date provided.
  """
  def event_matches?(record,eval_date) do
    %{ "!Parsed Rule" => rule_list} = record
    rules_parse(false, record, rule_list, eval_date)
  end

  # Receives a single rule list. A rule list is composed of rule components as
  # shown in the following:
  #   [ "June", "Day", "1"]
  # The rule is processed and true/false returned based on match to eval_date.
  defp rules_parse(true, _, _, _), do: true
  defp rules_parse(state, _, [], _), do: false
  defp rules_parse(state, record, parse_list, eval_date) do
    [ rule | tail_rules ] = parse_list
    match = rule_parse(record, rule, eval_date, nil)
    rules_parse(match, record, tail_rules, eval_date)
  end

  defp rule_parse(record, rule, eval_date, nil) do
    rule_parse(record, rule, eval_date, eval_date)
  end
  defp rule_parse(record, [], eval_date, build_date) do
    Timex.compare(build_date, eval_date, :days) == 0
  end
  defp rule_parse(record, rule, eval_date, build_date) do
    [ rule_part | rule_tail ] = rule
    cond do

      rule_date? rule_part ->
        { :ok, date } = Timex.parse(rule_part, "{D}-{Mshort}-{YYYY}")
        rule_parse(record, [], eval_date, date)

      rule_part == "Everyday" ->
        true

      rule_part == "Nextday" ->
        date = Timex.shift(build_date, days: 1)
        rule_parse(record, rule_tail, eval_date, date)

      rule_day_name? rule_part ->
        build_day_of_week = Timex.days_to_beginning_of_week(build_date) + 1
        rule_day_of_week = Timex.day_to_num rule_part
        shift_count = rem(rule_day_of_week - build_day_of_week + 7,7)
        date = Timex.shift(build_date, days: shift_count)
        rule_parse(record, rule_tail, eval_date, date)

      rule_month_name? rule_part ->
        month_num = Timex.month_to_num rule_part
        date = Timex.set(build_date, [month: month_num])
        rule_parse(record, rule_tail, eval_date, date)

      rule_part == "Day" ->
        [ string_day_num | new_tail ] = rule_tail
        {day_num, _} = Integer.parse(string_day_num)
        date = Timex.set(build_date, [day: day_num])
        rule_parse(record, new_tail, eval_date, date)

      rule_part == "Weekday" ->
        build_day_of_week = Timex.days_to_beginning_of_week(build_date) + 1
        cond do
          build_day_of_week <= 5 ->
            rule_parse(record,rule_tail, eval_date, build_date)
          true ->
            date = Timex.shift(build_date, days: 8-build_day_of_week)
            rule_parse(record,rule_tail, eval_date, date)
        end

      rule_part == "Lastday" ->
        date = Timex.end_of_month(build_date)
        rule_parse(record, rule_tail, eval_date, date)

      rule_part == "Businessday" ->
        date = build_date
        [ string_shift_count | new_tail ] = rule_tail
        { shift_count, _} = Integer.parse(string_shift_count)
        build_day_of_week = Timex.days_to_beginning_of_week(date) + 1
        # Move to Monday if on Saturday or Sunday
        cond do
          build_day_of_week <= 5 ->
            date
          true ->
            date = Timex.shift(date, days: 8-build_day_of_week)
        end
        # Shift whole weeks where possible
        week_count = div(shift_count,5)
        shift_count = rem(shift_count,5)
        date = Timex.shift(date, days: week_count * 7)
        # Businessday shift is now less than 5.
        cond do
          build_day_of_week + shift_count > 5 ->
            date = Timex.shift(date, days: shift_count + 2)
          true ->
            date = Timex.shift(date, days: shift_count)
        end
        rule_parse(record,new_tail, eval_date, date)

      true ->
        IO.puts "Unknown Rule Part: "
        IO.inspect rule_part
        false
    end
#    datetime = Timex.parse(rule_part, "{D}-{Mshort}-{YYYY}")
#    IO.inspect datetime
#    true
  end

  defp rule_date?(rule_part) do
    { match, _ } = Timex.parse(rule_part, "{D}-{Mshort}-{YYYY}")
    match == :ok
  end

  defp rule_day_name?(rule_part) do
    result = Timex.day_to_num rule_part
    case result do
      { :error, _ } ->
        false
      _ ->
        true
    end
  end

  defp rule_month_name?(rule_part) do
    result = Timex.month_to_num rule_part
    case result do
      { :error, _ } ->
        false
      _ ->
        true
    end
  end

  def is_type(record, type) do
    case record do
      %{ "!Type" => ^type } ->
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
      is_prefixed = String.starts_with?(a,"!")
      case is_prefixed do
        false ->
          IO.binwrite file, a <> " :: " <> b <> "\n"
        _ ->
      end
    end
    IO.binwrite file, "\n"
  end

# Reads the list file and creates a set of maps in a list. Each map holds a
# record from the file.
  defp load_lists do
    data = File.read!(Application.fetch_env!(:lists, :list_file))
    load_data data
  end

  def load_data(data) do

    Agent.start_link(fn -> 0 end, name: RecordCounter)

    list = data
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

    Agent.stop(RecordCounter,:normal)

    list

#      Enum.reduce list, [], fn record, newlist ->

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
    count = Agent.get_and_update(RecordCounter, fn(n) -> {n + 1, n + 1} end)

    case record do
      %{ "Rule" => rule } ->
        Map.merge(record, %{ "!Type" => "Event", "!Parsed Rule" => parse_rule(rule), "!Record ID" => count})
      %{ "List Name" => _ } ->
        Map.merge(record, %{ "!Type" => "List", "!Record ID" => count})
      %{ "Tag" => _ } ->
        Map.merge(record, %{ "!Type" => "Tag", "!Record ID" => count})
      _ ->
        Map.merge(record, %{ "!Type" => "Unknown", "!Record ID" => count})
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
      |> Enum.map(&(String.slice(&1,1..-2)))
      |> Enum.map(&(String.strip(&1)))
      |> Enum.map(&(String.split(&1," ")))
  end

end
