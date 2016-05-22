defmodule Lists.DayEntry do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/dayentry.html.eex"), [:date])

  def listdays do
    date = Timex.Date.now(Timex.Timezone.local())
    0..4
      |> Enum.map(&(Timex.shift(date, days: &1)))
      |> Enum.map(&(Lists.DayEntry.base(&1)))
  end

  def formatted_date(date) do
    { :ok, fdate } = Timex.format(date, "{WDfull} : {0D}-{Mshort}-{YYYY}")
    fdate
  end

end
