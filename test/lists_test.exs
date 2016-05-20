defmodule ListsTest do
  use ExUnit.Case
  doctest Lists

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "Rule Date Evaluation" do
    lists =
"""
Name :: Rule Date Test
Rule :: { 04-Sep-1955 }, { 21-Apr-2007 }
"""
    records = DataServer.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("21-Apr-2007", "{D}-{Mshort}-{YYYY}")
    assert DataServer.event_matches?(record, date)

    { :ok, date } = Timex.parse("04-Sep-1955", "{D}-{Mshort}-{YYYY}")
    assert DataServer.event_matches?(record, date)

    { :ok, date } = Timex.parse("22-Apr-2007", "{D}-{Mshort}-{YYYY}")
    refute = DataServer.event_matches?(record, date)
  end

  test "Rule Day Name Evaluation" do
    lists =
"""
Name :: Rule Day Name Test
Rule :: { Friday }
"""
    records = DataServer.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    assert = DataServer.event_matches?(record, date)

    { :ok, date } = Timex.parse("21-May-2016", "{D}-{Mshort}-{YYYY}")
    assert = DataServer.event_matches?(record, date)
  end

  test "Rule Day Number Evaluation" do
    lists =
"""
Name :: Rule Day Number Test
Rule :: { Day 20 }
"""
    records = DataServer.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    match = DataServer.event_matches?(record, date)
    assert match

    { :ok, date } = Timex.parse("21-May-2016", "{D}-{Mshort}-{YYYY}")
    match = DataServer.event_matches?(record, date)
    assert !match
  end

  test "Rule Lastday Evaluation" do
    lists =
"""
Name :: Rule Lastday Test
Rule :: { Lastday }
"""
    records = DataServer.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("31-May-2016", "{D}-{Mshort}-{YYYY}")
    match = DataServer.event_matches?(record, date)
    assert match

    { :ok, date } = Timex.parse("21-May-2016", "{D}-{Mshort}-{YYYY}")
    match = DataServer.event_matches?(record, date)
    assert !match
  end

  test "Rule Weekday Evaluation" do
    lists =
"""
Name :: Rule Weekday Test
Rule :: { Weekday }
"""
    records = DataServer.load_data lists
    [ record | _ ] = records
    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    match = DataServer.event_matches?(record, date)
    assert match

    { :ok, date } = Timex.parse("21-May-2016", "{D}-{Mshort}-{YYYY}")
    match = DataServer.event_matches?(record, date)
    assert !match
  end

  test "Rule Businessday Evaluation" do
    lists =
"""
Name :: Rule Businessday Test
Rule :: { Day 19 Businessday 2 }
"""
    records = DataServer.load_data lists
    [ record | _ ] = records

    { :ok, date } = Timex.parse("23-May-2016", "{D}-{Mshort}-{YYYY}")
    match = DataServer.event_matches?(record, date)
    assert match

    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    match = DataServer.event_matches?(record, date)
    assert !match
  end

  test "Rule Third Thursday Evaluation" do
    lists =
"""
Name :: Rule Third Thursday Test
Rule :: { Day 1 Thursday Nextday Thursday Nextday Thursday }
"""
    records = DataServer.load_data lists
    [ record | _ ] = records

    { :ok, date } = Timex.parse("19-May-2016", "{D}-{Mshort}-{YYYY}")
    assert = DataServer.event_matches?(record, date)

    { :ok, date } = Timex.parse("20-May-2016", "{D}-{Mshort}-{YYYY}")
    refult = DataServer.event_matches?(record, date)
  end

end
