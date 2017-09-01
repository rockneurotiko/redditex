# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :reditex,
  token: {:system, "BOT_TOKEN"},
  reddit_token: {:system, "REDDIT_TOKEN"},
  reddit_client: {:system, "REDDIT_CLIENT"},
  redirect_uri: {:system, "REDIRECT_URI"},
  port_server: {:system, "PORT_SERVER"},
  mongo_host: {:system, "MONGO_HOST"},
  mongo_db: {:system, "MONGO_DB"}

#     import_config "#{Mix.env}.exs"
