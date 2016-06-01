defmodule Lists.Router do
  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger
  end

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
    conn
      |> Lists.GenWebPage.page
      |> send_resp
  end

  get "/check" do
    %{ "record" => record_id, "date" => date, "instance" => instance} = conn.params
    DataServer.check(record_id)


    conn
      |> put_resp_header("location", "/")
      |> put_resp_content_type("text/html")
      |> send_resp(302,"")
#      |> halt
  end

    match _ do
      conn
      |> send_resp(404, "Nothing here")
      |> halt
    end

end
