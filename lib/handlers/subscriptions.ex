defmodule Handlers.Subscriptions do
  defmacro __using__(_) do
    quote do
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

      def handle({:callback_query, %{data: "unsubscribe:list:" <> srname} = msg}, name, %{uid: uid}) do
        {text, _success} =
          case Mongito.delete_subscription(uid, srname) do
            {:ok, _} -> {"You are unsubscribed to #{srname}!", false}
            _ -> {"Some error happened unsubscribing to #{srname}, try again later?", true}
          end

        subs_rows = Mongito.get_subscriptions(uid) |> Enum.map(&([[text: &1, callback_data: "unsubscribe:list:#{&1}"]]))
        bottom = [[[text: "Menu", callback_data: "show:mainmenu"]]]
        kboard = create_inline(subs_rows ++ bottom)

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
    end
  end
end
