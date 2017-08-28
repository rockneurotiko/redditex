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
      supervisor(Registry, [:unique, Registry.Subreddits, [partitions: System.schedulers_online()]]),
      worker(Mongo, [[name: :mongo, hostname: mhost, database: mdb, pool: DBConnection.Poolboy]]),
      supervisor(Telex, []),
      supervisor(Reditex, [:polling, Telex.Config.get(:reditex, :token)]),
      Plug.Adapters.Cowboy.child_spec(:http, Reditex.Router, [], port: port)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Reditex.Supervisor]
    case Supervisor.start_link(children, opts) do
      {:ok, _} = r ->
        SubredditWatcher.create_initials
        r
      e -> e
    end
  end
end
