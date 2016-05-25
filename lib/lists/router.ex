defmodule Lists.Router do
  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger
  end

  plug Plug.Static,
  at: "/", from: "priv/static",
  only: ~w(css images js favicon.ico logo.png robots.txt checkmark.png)

  plug :match
  plug :dispatch

  # Root path
  get "/" do
    send_resp(conn, 200, Lists.GenWebPage.page)
  end

  get "/checked" do
    conn = fetch_query_params(conn,"") # populates conn.params
    %{ "event" => event} = conn.params
    DataServer.check(event)

    conn
      |> put_resp_header("location", "/")
      |> put_resp_content_type("text/html")
      |> send_resp(302,"")
      |> halt
  end


  get "/about/:name" do
    send_resp(conn, 200, "#{name} is vital to our website's continued success.")
  end

  get "/json/:name" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{name: name}))
  end

    match _ do
      conn
      |> send_resp(404, "Nothing here")
      |> halt
    end

end
