defmodule Lists.Router do
  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger
  end

  plug Plug.Parsers, parsers: [:urlencoded]

  plug Plug.Session,
    store: :cookie,
#    key: "filelif_lists_cookie",
    key: Application.fetch_env!(:lists, :session_key),
    signing_salt: "Jk7pxAMf"

  plug Plug.Static,
  at: "/", from: "priv/static",
  only: ~w(css images js favicon.ico logo.png robots.txt checkmark.png)

  plug :put_secret_key_base

  def put_secret_key_base(conn, _) do
    the_key = Application.fetch_env!(:lists, :secret_key)
      |> String.duplicate(4)
    put_in conn.secret_key_base, the_key
  end

  plug :session_manager

  def session_manager(conn, _) do
    conn
    |> fetch_session
    |> fetch_query_params("")
      |> Lists.SessionManager.check_session
      |> Lists.SessionManager.touch_session
  end

#  IO.puts "Common Code Here"
#  IO.inspect conn

  plug :match
  plug :dispatch

  # Root path
  get "/" do
    {:ok, show_date} = Lists.SessionManager.get_session_parameter(conn,"Show Date")
    if show_date == nil do
      show_date = Timex.Date.now(Timex.Timezone.local())
      Lists.SessionManager.set_session_parameter(conn, "Show Date", show_date)
    end
    conn
      |> Lists.GenWebPage.page(show_date)
      |> send_resp
  end

  get "/show" do
    %{"showdate" => show_date} = conn.params
    cond do
      show_date == "overdue" ->
#        IO.puts "Showing Overdue List"
        Lists.SessionManager.set_session_parameter(conn, "Show Date", "overdue")
#        Lists.SessionManager.set_session_parameter(conn, "Show Date", Timex.Date.now(Timex.Timezone.local()))
      true ->
        {:ok, show_date} = Timex.parse(show_date, "{0D}-{Mshort}-{YYYY}")
        Lists.SessionManager.set_session_parameter(conn, "Show Date", show_date)
    end
    conn
      |> put_resp_header("location", "/")
      |> put_resp_content_type("text/html")
      |> send_resp(302,"")
  end

  get "/check" do
    %{ "record" => record_id, "date" => date, "instance" => instance} = conn.params
    DataServer.check(record_id, date, instance)

    conn = conn
      |> put_resp_header("location", "/")
      |> put_resp_content_type("text/html")
      |> send_resp(302,"")

    DataServer.write_lists

    conn
#      |> halt
  end

  get "/button/events" do
    conn
      |> put_resp_header("location", "/")
      |> put_resp_content_type("text/html")
      |> send_resp(302,"")
  end

  get "/button/add" do
    conn
      |> Lists.AddEventPage.page
      |> send_resp
  end

  post "/newevent" do
#    %{ "event" => new_event} = conn.params
    IO.inspect conn.params
    event = conn.params["event"]
    IO.inspect event
    record = Lists.Access.load_data event
    IO.inspect record
    conn
      |> send_resp(200, "New Event Received")
  end

    match _ do
      conn
      |> send_resp(404, "Nothing here")
      |> halt
    end

end
