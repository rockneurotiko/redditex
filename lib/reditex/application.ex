defmodule Reditex.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    port = Telex.Config.get_integer(:reditex, :port_server, 8080)

    mhost = Telex.Config.get(:reditex, :mongo_host, "localhost")
    mdb = Telex.Config.get(:reditex, :mongo_db, "test")

    # Define workers and child supervisors to be supervised
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Reditex.Router, [], port: port),
      worker(Mongo, [[name: :mongo, hostname: mhost, database: mdb, pool: DBConnection.Poolboy]]),
      supervisor(Telex, []),
      supervisor(Reditex, [:polling, Telex.Config.get(:reditex, :token)]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Reditex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
