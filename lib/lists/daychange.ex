defmodule Lists.DayChange do
  use GenServer
  use Timex
  @moduledoc """
  This gen server watches for a date change. This allows all the events data
  to be updated. The server gets a message at 1 second after each new minute.
  If the date has changed, then the DataServer gets called to update the
  events.

  State kept by the server is the last date found when server ticked on last minute.

  %{ "List Date" => DateTime }
  """

  @doc """
  Start the link. This generates a call to 'init'.
  """
  def start_link do
    GenServer.start_link(__MODULE__, %{} , [name: DayChange])
  end

  @doc """
  Set up the state to the current date and set a trigger a new trigger.
  """
  def init _ do
    current_date = DateTime.now(Timezone.local())
#    IO.inspect get_delay_ms current_date
    Process.send_after(DayChange, :work, get_delay_ms current_date)
    {:ok, %{"List Date" => current_date} }
  end

  @doc """
  If the current date is not equal to the date held in state, then a request to reload the lists is sent to the data server. Otherwise, setup a new trigger.
  """
  def handle_info(:work, state) do
    list_date = state["List Date"]
    current_date =  DateTime.now(Timezone.local())
    if Timex.compare(list_date, current_date, :days) != 0 do
      IO.puts "Date Changed - Put Code To Do Update Here"
      state = %{"List Date" => current_date}
    end
#    IO.inspect current_date
    Process.send_after(DayChange, :work, get_delay_ms current_date)
    {:noreply, state}
  end

  # Calculates then number of milliseconds to the first second after a new
  # minute.
  defp get_delay_ms date do
    ((60 - date.second) + 1) * 1000
  end
end
