defmodule Handlers.MainMenu do
  defmacro __using__(_) do
    quote do
      def handle({:callback_query, %{data: "show:mainmenu"} = msg}, name, %{uid: uid}) do
        kboard =
          [[[text: "My subreddits", callback_data: "show:subreddits:page:actual"]],
           [[text: "My subscriptions", callback_data: "show:user:subscriptions"]],
           [[text: "Front", callback_data: "show:subreddit:_front:page:actual"]]] |> create_inline

        edit :inline, msg, "Main menu", reply_markup: kboard, bot: name
      end
    end
  end
end
