defmodule Reditex do
  use Telex.Bot,
    name: :reditex,
    commands: [[command: "help", name: :help],
              [command: "auth", name: :auth],
              [command: "mysubs", name: :mysubs]],
    middlewares: [Reditex.UserMiddleware, Reditex.AuthMiddleware]

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
        Reditex.AuthMiddleware.auth_response(s, uid)

        Telex.send_message uid, "Authenticated! You can see your subreddits with /mysubs", bot: :reditex
      _ ->
        Telex.send_message uid, "Some weird error man! WTF!", bot: :reditex
    end
  end

  # HANDLER


  def handle(_, name, %{update: msg, error: :create_user_info}) do
    Logger.info "ERROR"
    answer msg, "Some error happened, sorry!", bot: name
  end

  def handle({:command, :help, msg}, name, _) do
    answer msg, "Help? Not here:)", bot: name
  end

  def handle({:command, :auth, msg}, name, %{uid: uid}) do
    url = RedditApi.initial_authorize_url(uid)
    answer msg, "Authenticate here: #{url}", bot: name
  end

  def handle(_, name, %{update: msg, uid: uid, error: :auth}) do
    Logger.info "ERROR NO AUTH"
    url = RedditApi.initial_authorize_url(uid)
    answer msg, "You are not authenticated, follow the link: #{url}", bot: name
  end

  def handle({:command, :mysubs, msg}, name, %{token: token}) do
    origin_subs = RedditApi.subreddits(token)
    subs = origin_subs |> Utils.subreddits_names

    answer msg, "Your subreddits: \n#{Enum.join(subs, "\n")}", bot: name
  end

  def handle(msg, name, extra) do
    Logger.warn "Unknown message on bot #{inspect name}: #{inspect msg} with extra #{inspect extra}"
  end
end
