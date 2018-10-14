defmodule Lists.GenWebPage do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/header.html.eex"), [:date])

  @doc """
  Generates the user page for the selected lists.
  - Checks session to see if it exists.
  -
  """
  def page(conn, date) do
    #    sessions = Lists.SessionManager.get_sessions
    #    IO.inspect sessions
    #    session = Lists.SessionManager.get_session_by_connection(conn)
    #    IO.inspect session

    conn
    |> Plug.Conn.resp(200, base(date))
  end
end
