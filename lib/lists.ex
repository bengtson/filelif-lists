defmodule Lists do
  use Application

  def start( _type, _args ) do
    import Supervisor.Spec, warn: false

    children = [
      worker(__MODULE__, [], function: :run),
      supervisor(DataServer, [])
    ]

    opts = [strategy: :one_for_one, name: Lists.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def run do
    IO.puts "Starting Cowboy"
    { :ok, _ } = Plug.Adapters.Cowboy.http Lists.Router, [], port: 7575
  end
end
