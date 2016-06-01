defmodule Lists.Events.Rules do

    @doc """
    Checks the provided event record to see if it is active for the evalute date provided.
    """
    def event_matches?(record,eval_date) do
      %{ "Meta Data" => meta_data } = record
      %{ "Parsed Rule" => rule_list} = meta_data
      rules_parse(false, record, rule_list, eval_date)
    end

    # Receives a single rule list. A rule list is composed of rule components as
    # shown in the following:
    #   [ "June", "Day", "1"]
    # The rule is processed and true/false returned based on match to eval_date.
    defp rules_parse(true, record, _, build_date) do
      checked_date_string = record["Checked"]
      cond do
        checked_date_string == nil ->
          true
        true ->
          {:ok, checked_date} = Timex.parse(checked_date_string, "{D}-{Mshort}-{YYYY}")
          ! Timex.equal?(checked_date, build_date)
      end
    end
    defp rules_parse(_, _, [], _), do: false
    defp rules_parse(_, record, parse_list, eval_date) do
      [ rule | tail_rules ] = parse_list
      match = rule_parse(record, rule, eval_date, nil)
      rules_parse(match, record, tail_rules, eval_date)
    end

    defp rule_parse(record, rule, eval_date, nil) do
      rule_parse(record, rule, eval_date, eval_date)
    end
    defp rule_parse(_, [], eval_date, build_date) do
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
          date = Timex.set(build_date, [month: month_num, day: 1])
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

end
