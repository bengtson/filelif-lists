defmodule Lists.DayEntry do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/dayentry.html.eex"), [:date])

  EEx.function_from_file(:def, :dayletter, Path.expand("./templates/dayentry.letter.html.eex"), [:entry])

  def listdays do
    date = Timex.Date.now(Timex.Timezone.local())
    0..0
      |> Enum.map(&(Timex.shift(date, days: &1)))
      |> Enum.map(&(Lists.DayEntry.base(&1)))
  end

  def formatted_date(date) do
    Timex.format(date, "{WDfull} : {0D}-{Mshort}-{YYYY}")
      |> elem(1)
  end

  def letters do
    date = Timex.Date.now(Timex.Timezone.local())
    6..0
      |> Enum.map(&(Timex.shift(date, days: &1)))
      |> Enum.map(&(create_letter_map(&1)))
      |> Enum.map(&(Lists.DayEntry.dayletter(&1)))
  end

  def create_letter_map(date) do
    %{
      "Bold" => date == Timex.Date.now(Timex.Timezone.local()),
      "Letter" => Timex.weekday(date)
                    |> Timex.day_name
                    |> String.first,
      "Hover"  => formatted_date(date)
    }
  end

end
