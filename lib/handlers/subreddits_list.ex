defmodule Handlers.SubredditsList do
  defmacro __using__(_) do
    quote do
      def handle({:callback_query, %{data: "show:subreddits:show:" <> sbname} = msg}, name, %{uid: uid}) do
        sub = Mongito.subscribed?(uid, sbname)

        kboard = Utils.subreddit_keyboard(sbname, sub)

        edit :inline, msg, "Subreddit #{sbname}", reply_markup: kboard, bot: name
      end

      def handle({:callback_query, %{data: "show:subreddits:page:" <> dir} = msg}, name, %{token: token, uid: uid, stack: stack}) do

        ndrop = case dir do
                  "prev" -> 2
                  "actual" -> 1
                  "next" -> 0
                  "veryprev" -> length(stack)
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

        bottom = [[[text: "Menu", callback_data: "show:mainmenu"]]]

        keyb = Utils.list_keyboard(subs, "show:subreddits", length(new_stack) == 1, sub_after == "", bottom)

        edit :inline, msg, "Your subreddits!", reply_markup: keyb, bot: name
      end
    end
  end
end
