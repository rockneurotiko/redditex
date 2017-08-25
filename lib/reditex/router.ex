defmodule Reditex.Router do
  use Plug.Router

  require Logger

  plug Plug.Parsers, parsers: [:json]
  plug Plug.Logger

  plug :match
  plug :dispatch

  get "/" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, %{"ok" => true} |> Poison.encode!)
  end

  get "/authorize_callback" do
    Reditex.user_auth_answer(conn.params)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, %{"ok" => true} |> Poison.encode!)
  end

  match _ do
    conn |> send_resp(404, "notjier")
  end
end
