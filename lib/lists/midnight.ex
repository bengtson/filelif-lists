defmodule Lists.Midnight do
  use GenServer
  use Timex

  def start_link do
    GenServer.start_link(__MODULE__, %{}, [name: Midnight])
  end

  def init(state) do
    IO.inspect get_delay_ms
    Process.send_after(self(), :work, get_delay_ms)
    {:ok, {} }
  end

  def handle_info(:work, state) do
    IO.inspect Timex.Date.now(Timex.Timezone.local())
    Process.send_after(self(), :work, get_delay_ms)
    {:noreply, state}
  end

  def get_delay_ms do
    %DateTime{ hour: hours, minute: minutes} = DateTime.now(Timex.Timezone.local())
    ((23 - hours) * 60 + (60 - minutes)) * 60 * 1000
  end
end
