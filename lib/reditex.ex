defmodule Reditex do
  use Telex.Bot,
    name: :reditex,
    commands: [[command: "help", name: :help],
              [command: "auth", name: :auth],
              [command: "mysubs", name: :mysubs]],
    middlewares: [Reditex.UserMiddleware,
                  Reditex.AuthMiddleware,
                  Reditex.StateMiddleware]

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

  def handle(_, name, %{update: msg, error: :state}) do
    Logger.info "ERROR STATE"
    answer msg, "Some error happened, sorry!", bot: name
  end


  # LIST SUBREDDITS

  # BASE COMMAND

  def handle({:command, :mysubs, msg}, name, %{uid: uid, token: token}) do
    origin_subs = RedditApi.subreddits(token, limit: 10)
    subs = origin_subs |> Utils.subreddits_names |> Enum.map(&({&1, "show:#{&1}"}))

    stack = Utils.sub_after(origin_subs)

    Mongito.set_stack(uid, [stack])

    keyb = Utils.list_keyboard(subs, "show:subreddits", true, stack == "")

    answer msg, "Your subreddits", reply_markup: keyb, bot: name
  end

  # CB

  def handle({:callback_query, %{data: "show:subreddits:show:" <> sbname} = msg}, name, %{uid: uid}) do

    sub = Mongito.subscribed?(uid, sbname)

    kboard = Utils.subreddit_keyboard(sbname, sub)

    Mongito.set_post_stack(uid, [])

    edit :inline, msg, "Subreddit #{sbname}", reply_markup: kboard, bot: name
  end

  # CB SUBSCRIPTIONS

  def handle({:callback_query, %{data: "subscribe:" <> srname} = msg}, name, %{uid: uid}) do
    {text, success} =
      case Mongito.save_subscription(uid, srname) do
        {:ok, _} -> {"You are subscribed to #{srname}!", true}
        _ -> {"Some error happened subscribing to #{srname}, try again later?", false}
      end

    SubredditWatcher.start_watcher(srname)

    kboard = Utils.subreddit_keyboard(srname, success)

    edit :inline, msg, text, reply_markup: kboard, bot: name
  end

  def handle({:callback_query, %{data: "unsubscribe:" <> srname} = msg}, name, %{uid: uid}) do
    {text, success} =
      case Mongito.delete_subscription(uid, srname) do
        {:ok, _} -> {"You are unsubscribed to #{srname}!", false}
        _ -> {"Some error happened unsubscribing to #{srname}, try again later?", true}
      end

    kboard = Utils.subreddit_keyboard(srname, success)

    edit :inline, msg, text, reply_markup: kboard, bot: name
  end


  def handle({:callback_query, %{data: "show:subreddits:page:veryprev"} = msg}, name, %{token: token, uid: uid}) do
    origin_subs = RedditApi.subreddits(token, limit: 10)
    subs = origin_subs |> Utils.subreddits_names |> Enum.map(&({&1, "show:#{&1}"}))

    stack = Utils.sub_after(origin_subs)

    Mongito.set_stack(uid, [stack])

    keyb = Utils.list_keyboard(subs, "show:subreddits", true, stack == "")

    edit :inline, msg, "Your subreddits!", reply_markup: keyb, bot: name
  end

  def handle({:callback_query, %{data: "show:subreddits:page:" <> dir} = msg}, name, %{token: token, uid: uid, stack: stack}) do

    ndrop = case dir do
              "prev" -> 2
              "actual" -> 1
              "next" -> 0
            end

    {elem, new_stack} = case stack |> Enum.reverse |> Enum.drop(ndrop) do
                          [] -> {"", []}
                          [x|_] = xl -> {x, xl |> Enum.reverse}
                        end

    origin_subs = RedditApi.subreddits(token, limit: 10, after: elem)
    subs = origin_subs |> Utils.subreddits_names |> Enum.map(&({&1, "show:#{&1}"}))

    sub_after = Utils.sub_after(origin_subs)

    new_stack = new_stack ++ [sub_after]

    Mongito.set_stack(uid, new_stack)

    keyb = Utils.list_keyboard(subs, "show:subreddits", length(new_stack) == 1, sub_after == "")

    edit :inline, msg, "Your subreddits!", reply_markup: keyb, bot: name
  end

  def handle(msg, name, extra) do
    Logger.warn "Unknown message on bot #{inspect name}: #{inspect msg} with extra #{inspect extra}"
  end
end
