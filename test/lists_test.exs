defmodule ListsTest do
  use ExUnit.Case
  doctest Lists

  test "Rule Date Evaluation" do
    lists =
"""
Name :: Rule Date Test
Rule :: { 04-Sep-1955 }, { 21-Apr-2007 }
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("21-Apr-2007", "{D}-{Mshort}-{YYYY}")
    assert Lists.Events.Rules.event_matches?(record, date)

    { :ok, date } = Timex.parse("04-Sep-1955", "{D}-{Mshort}-{YYYY}")
    assert Lists.Events.Rules.event_matches?(record, date)

    { :ok, date } = Timex.parse("22-Apr-2007", "{D}-{Mshort}-{YYYY}")
    refute Lists.Events.Rules.event_matches?(record, date)
  end

  test "Rule Day Name Evaluation" do
    lists =
"""
Name :: Rule Day Name Test
Rule :: { Friday }
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    assert Lists.Events.Rules.event_matches?(record, date)

    { :ok, date } = Timex.parse("21-May-2016", "{D}-{Mshort}-{YYYY}")
    refute Lists.Events.Rules.event_matches?(record, date)
  end

  test "Rule Day Number Evaluation" do
    lists =
"""
Name :: Rule Day Number Test
Rule :: { Day 20 }
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    match = Lists.Events.Rules.event_matches?(record, date)
    assert match

    { :ok, date } = Timex.parse("21-May-2016", "{D}-{Mshort}-{YYYY}")
    match = Lists.Events.Rules.event_matches?(record, date)
    assert !match
  end

  test "Rule Lastday Evaluation" do
    lists =
"""
Name :: Rule Lastday Test
Rule :: { Lastday }
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("31-May-2016", "{D}-{Mshort}-{YYYY}")
    match = Lists.Events.Rules.event_matches?(record, date)
    assert match

    { :ok, date } = Timex.parse("21-May-2016", "{D}-{Mshort}-{YYYY}")
    match = Lists.Events.Rules.event_matches?(record, date)
    assert !match
  end

  test "Rule Weekday Evaluation" do
    lists =
"""
Name :: Rule Weekday Test
Rule :: { Weekday }
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    match = Lists.Events.Rules.event_matches?(record, date)
    assert match

    { :ok, date } = Timex.parse("21-May-2016", "{D}-{Mshort}-{YYYY}")
    match = Lists.Events.Rules.event_matches?(record, date)
    assert !match
  end

  test "Rule Businessday Evaluation" do
    lists =
"""
Name :: Rule Businessday Test
Rule :: { Day 19 Businessday 2 }
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records

    { :ok, date } = Timex.parse("23-May-2016", "{D}-{Mshort}-{YYYY}")
    match = Lists.Events.Rules.event_matches?(record, date)
    assert match

    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    match = Lists.Events.Rules.event_matches?(record, date)
    assert !match
  end

  test "Rule Third Thursday Evaluation" do
    lists =
"""
Name :: Rule Third Thursday Test
Rule :: { Day 1 Thursday Nextday Thursday Nextday Thursday }
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records

    { :ok, date } = Timex.parse("19-May-2016", "{D}-{Mshort}-{YYYY}")
    assert Lists.Events.Rules.event_matches?(record, date)

    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    refute Lists.Events.Rules.event_matches?(record, date)
  end

  test "Check Overdue Eval Data Generation On Rule" do
    lists =
"""
Name :: Overdue Eval Data Created Test
Rule :: { May Day 31 }
Checked :: 30-May-2016
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("01-Jun-2016", "{D}-{Mshort}-{YYYY}")
    date = Timex.date(date)
    record = Lists.Events.Overdue.generate_overdue_data record, date
    eval_data = record["Eval Data"]
    assert (eval_data["Overdue Count"] == 1), "Overdue Count Not One"
    assert (eval_data["Overdue Type"] == :rules), "Overdue Not Type :rules"
  end

  test "Check Overdue Eval Data Generation On Single Date" do
    lists =
"""
Name :: Overdue Eval Data Single Date Test
Rule :: { 26-Mar-2016 }
"""
    records = Lists.Access.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("01-Jun-2016", "{D}-{Mshort}-{YYYY}")
    date = Timex.date(date)
    record = Lists.Events.Overdue.generate_overdue_data record, date
    eval_data = record["Eval Data"]
    assert (eval_data["Overdue Count"] == 66), "Overdue Count Not 66"
    assert (eval_data["Overdue Type"] == :single_date), "Overdue Not Type :single_date"
  end

end
