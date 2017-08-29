defmodule Handlers.User do
  defmacro __using__(_) do
    quote do
      def handle({:callback_query, %{data: "show:user:subscriptions"} = msg}, name, %{uid: uid}) do
        subs_rows = Mongito.get_subscriptions(uid) |> Enum.map(&([[text: &1, callback_data: "unsubscribe:list:#{&1}"]]))
        bottom = [[[text: "Menu", callback_data: "show:mainmenu"]]]
        keyb = create_inline(subs_rows ++ bottom)

        edit :inline, msg, "Your subscriptions, click to unsubscribe", reply_markup: keyb, bot: name
      end
    end
  end
end
