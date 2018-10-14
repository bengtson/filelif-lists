defmodule Lists.AddEventPage do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/addheader.html.eex"), [:map])

  @doc """
  Generates the user page for the selected lists.
  - Checks session to see if it exists.
  -
  """
  def page(conn) do
    map = %{"Example" => example_event()}

    conn
    |> Plug.Conn.resp(200, base(map))
  end

  # Example event.
  def example_event do
    "Name :: Event Name Here&#10;Rule :: { June Day 1 }&#10;Tag :: Home"
  end
end
