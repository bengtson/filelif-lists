defmodule Lists.AddEventPage do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/addheader.html.eex"))

  @doc """
  Generates the user page for the selected lists.
  - Checks session to see if it exists.
  -
  """
  def page conn do
    conn |>
      Plug.Conn.resp(200,base)
  end

end
