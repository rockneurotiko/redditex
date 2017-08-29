defmodule Reditex do
  use Telex.Bot,
    name: :reditex,
    commands: [[command: "help", name: :help],
               [command: "auth", name: :auth],
               [command: "subscribe", name: :subscribe],
               [command: "mysubs", name: :mysubs]],
    middlewares: [Reditex.UserMiddleware,
                  Reditex.AuthMiddleware,
                  Reditex.StateMiddleware,
                 Reditex.PostStackMiddleware]

  use Telex.Dsl

  require Logger

  # Finish authentication

  def user_auth_answer(%{"state" => uids} = s) when is_bitstring(uids) do
    case Integer.parse(uids) do
      {uid, ""} ->
        user_auth_answer(Map.put(s, "state", uid))
      _ ->
        Logger.warn "Error parsing state?"
    end
  end
  def user_auth_answer(%{"error" => _, "state" => uid}) do
    Telex.send_message uid, "Next time allow me to work :)", bot: :reditex
  end

  def user_auth_answer(%{"code" => code, "state" => uid}) do
    case RedditApi.access_token(code) do
      {:ok, s} ->
        Auth.auth_response(s, uid)

        Telex.send_message uid, "Authenticated! You can see your subreddits with /mysubs", bot: :reditex
      _ ->
        Telex.send_message uid, "Some weird error man! WTF!", bot: :reditex
    end
  end

  # HANDLERS

  use Handlers.Errors

  use Handlers.Commands

  use Handlers.MainMenu

  use Handlers.User

  use Handlers.Subreddit

  use Handlers.Subscriptions

  use Handlers.SubredditsList

  def handle(msg, name, extra) do
    Logger.warn "Unknown message on bot #{inspect name}: #{inspect msg} with extra #{inspect extra}"
  end
end
