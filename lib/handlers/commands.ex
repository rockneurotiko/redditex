defmodule Handlers.Commands do
  defmacro __using__(_) do
    quote do
      # BASE COMMAND

      @subreddit ~r/(\/r\/)?([^ ]+)$/

      def handle({:command, :mysubs, msg}, name, %{uid: uid, token: token}) do
        origin_subs = RedditApi.subreddits(token, limit: 10)
        subs = origin_subs |> Utils.subreddits_names |> Enum.map(&({&1, "show:#{&1}"}))

        stack = Utils.sub_after(origin_subs)

        Mongito.set_stack(uid, [stack])

        bottom = [[[text: "Menu", callback_data: "show:mainmenu"]]]

        keyb = Utils.list_keyboard(subs, "show:subreddits", true, stack == "", bottom)

        answer msg, "Your subreddits", reply_markup: keyb, bot: name
      end

      def handle({:command, :subscribe, %{text: text} = msg}, name, %{uid: uid}) do
        case Regex.run(@subreddit, text) do
          nil ->
            answer msg, "Bad formatted subreddit", bot: name
          [_text, _r, subreddit] ->
            if Mongito.subscribed?(uid, subreddit) do
              answer msg, "You are already subscribed to #{subreddit}", bot: name
            else
              Mongito.save_subscription(uid, subreddit)
              answer msg, "Subscribed to #{subreddit}!", bot: name
            end
        end
      end
    end
  end
end
