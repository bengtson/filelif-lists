defmodule Lists.Router do
  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger
  end

  plug Plug.Static,
  at: "/", from: "priv/static",
  only: ~w(css images js favicon.ico logo.png robots.txt)

  plug :match
  plug :dispatch

  # Root path
  get "/" do
    # IO.puts inspect conn
    send_resp(conn, 200, Lists.GenWebPage.page)
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
