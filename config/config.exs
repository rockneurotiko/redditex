# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :reditex,
  token: {:system, "BOT_TOKEN"},
  reddit_token: {:system, "REDDIT_TOKEN"},
  reddit_client: {:system, "REDDIT_CLIENT"},
  port_server: 8080,
  mongo_host: "localhost",
  mongo_db: "reditex"

#     import_config "#{Mix.env}.exs"
