defmodule Lists.DayEntry do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/dayentry.html.eex"), [:date, :overdue])

  EEx.function_from_file(:def, :dayletter, Path.expand("./templates/dayentry.letter.html.eex"), [:entry])

  def listdays date do
    cond do
      date == "overdue" ->
        date = Timex.Date.now(Timex.Timezone.local())
        0..0
          |> Enum.map(&(Timex.shift(date, days: &1)))
          |> Enum.map(&(Lists.DayEntry.base(&1,true)))
      true ->
        0..0
          |> Enum.map(&(Timex.shift(date, days: &1)))
          |> Enum.map(&(Lists.DayEntry.base(&1,false)))
    end
  end

  def formatted_date(date) do
    Timex.format(date, "{WDfull} : {0D}-{Mshort}-{YYYY}")
      |> elem(1)
  end

  def letters show_date do
    date = Timex.Date.now(Timex.Timezone.local())
    6..0
      |> Enum.map(&(Timex.shift(date, days: &1)))
      |> Enum.map(&(create_letter_map(&1, show_date)))
      |> Enum.map(&(Lists.DayEntry.dayletter(&1)))
  end

  def create_letter_map(date, show_date) do
    show_date = Timex.date(show_date)
    {:ok, url_date} = Timex.format(date, "{0D}-{Mshort}-{YYYY}")
    %{
      "Bold" => (date == show_date),
      "Letter" => Timex.weekday(date)
                    |> Timex.day_name
                    |> String.first,
      "Hover"  => formatted_date(date),
      "Url" => "/show?showdate=" <> url_date
    }
  end

end
