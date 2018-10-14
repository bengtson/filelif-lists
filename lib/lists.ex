defmodule Lists do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(__MODULE__, [], function: :run),
      supervisor(DataServer, []),
      supervisor(Lists.SessionManager, []),
      supervisor(Lists.DayChange, [])
    ]

    opts = [strategy: :one_for_one, name: Lists.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def run do
    {:ok, _} = Plug.Adapters.Cowboy2.http(Lists.Router, [], port: 7576)
  end
end
