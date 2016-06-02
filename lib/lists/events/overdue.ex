defmodule Lists.Events.Overdue do
@moduledoc """
This module handles processing of event records in Lists.

## Algorithm for Overdue Calculations

### Create the 'Eval Data' Map
-  Set Overdue Last Date To Prior Day
-  Set Overdue First Date To Prior Day
-  Set Overdue Count to 0.

### Determine Type Of Event For Overdue Calculations

*Single Date* : If there is only one rule for the event and that rule is a full date, then type is :single_date. Single dates will simply provide the number of days since the event. This is only if the event is passed.

*Not Checked* : If not :single_date and if the event has not been checked, then the type is :not_checked. For 'not checked' items, nothing needs to be done. One cannot determine if anything is overdue.

*Rule* : If not one of the other types, then this is a :rule type. Rule types will count all days that the rule matches back until the last time the event was checked.

### About the Eval Map

The "Eval Map" is a map of parameters that is stored in the record. This map is generated for the programs use and nothing in the map gets written to disk when the Lists Compendium is stored. The map contains the following entries:

- Overdue Last Date => date : The last date in time that is checked for overdue status of the event.
- Overdue First Date => date : The first date in time that was checked for overdue status of the event. Checking overdue status starts with the day prior to the current day and moves back in time checking each date for a match against the rules. The First Date moves until it hits the "Checked" date.
- Overdue Count => integer : For single date records, this is then number of days the event is overdue. For rules records, this is the number of times the event was due between the current day and the last checked day.
"""

  @doc """
  Generates the "Eval Data" map associated with the record provided. A date needs to be supplied which is generally the day prior to the current day since nothing can really be overdue on the current day.
  """
  def generate_overdue_data(%{"Meta Data" => %{"Type" => "Event"}} = record, date) do
    date = Timex.date(date)
    date = Timex.shift(date, days: -1)
#    IO.inspect record["Name"]
#    IO.inspect date
    eval_map = %{
      "Overdue First Date" => date,
      "Overdue Last Date" => date,
      "Overdue Count" => 0
    }
    [first_rule | _] = record["Meta Data"]["Parsed Rule"]
    [first_rule | _] = first_rule
    { match, _ } = Timex.parse(first_rule, "{D}-{Mshort}-{YYYY}")
    single_date = (match == :ok)
    has_checked = Map.has_key?(record, "Checked")

    overdue_type = cond do
      single_date -> :single_date
      !has_checked -> :not_checked
      true -> :rules
    end
    eval_map = Map.merge(eval_map, %{"Overdue Type" => overdue_type})

    new_record = Map.merge(record, %{"Eval Data" => eval_map})

    generate_overdue_data_handler(overdue_type, new_record)
  end

  def generate_overdue_data(record, _) do
    record
  end

  # Following are the handlers that determine overdue counts. There is one
  # handler for each type of event record.

  # Calculate the number of days overdue and put that into the overdue count.
  def generate_overdue_data_handler(:single_date, record) do
    [rule_date_string | _] = record["Meta Data"]["Parsed Rule"]
    [rule_date_string | _] = rule_date_string
    overdue_last_date = record["Eval Data"]["Overdue Last Date"]
    checked = record["Meta Data"]["Checked"]

    { :ok, date } = Timex.parse(rule_date_string, "{D}-{Mshort}-{YYYY}")
    date = Timex.date date
    cond do
      checked != nil ->
        put_in(record, ["Eval Data","Overdue Count"], 0)
      Timex.after?(date, overdue_last_date) ->
        record
      true ->
        days = Timex.diff(date, overdue_last_date, :days)
        put_in(record, ["Eval Data","Overdue Count"], days)
    end
  end

  # Since this record has not been checked, it can't be considered overdue.
  # simply return the record.
  def generate_overdue_data_handler(:not_checked, record) do
    record
  end

  # Calculates the number of times this event has not been checked between
  # the provided date and the last checked date. This is done date by date
  # moving backwards.
  def generate_overdue_data_handler(:rules, record) do
#    name = record["Name"]
#    if name == "Feed Gabby and Lilly Breakfast" do
#      IO.inspect record
#    end
    first_overdue_date = record["Eval Data"]["Overdue First Date"]
    checked_date = record["Meta Data"]["Checked"]
    overdue_count = record["Eval Data"]["Overdue Count"]
    cond do
      Timex.before?(first_overdue_date, checked_date) ->
        record
      overdue_count >= 10 ->
        record
      Lists.Events.Rules.event_matches?(record, first_overdue_date) ->
        overdue_count = record["Eval Data"]["Overdue Count"]
        record = put_in(record,["Eval Data", "Overdue Count"], overdue_count+1)
        record = put_in(record,["Eval Data", "Overdue First Date"], Timex.shift(first_overdue_date, days: -1))
        generate_overdue_data_handler(:rules, record)
      true ->
        record = put_in(record,["Eval Data", "Overdue First Date"], Timex.shift(first_overdue_date, days: -1))
        generate_overdue_data_handler(:rules, record)
    end
  end

end
