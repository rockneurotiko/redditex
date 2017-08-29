defmodule Handlers.Subreddit do
  defmacro __using__(_) do
    quote do
      # Subreddit view

      def handle({:callback_query, %{data: "show:subreddit:" <> data} = msg}, name, %{token: token, uid: uid, post_stack: stack}) do
        [subreddit, "page", dir] = String.split(data, ":")

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

        with {:ok, posts} <- RedditApi.subreddit_posts(subreddit, token, limit: 1, after: elem),
             {:ok, first_post} <- Post.extract_first_post(posts),
             {:ok, post_data} <- Post.extract_post_data(first_post),
               post_after <- Utils.sub_after(posts) do
          text =
            case Post.post_to_text(post_data) do
              {:ok, text} -> text
              _ ->
                Logger.warn "Error decoding: #{inspect first_post} #{inspect post_data}"
                "Can't decode this post, sorry!"
            end

          new_stack = new_stack ++ [post_after]
          Mongito.set_post_stack(uid, subreddit, new_stack)

          arrows = Utils.listing_arrows("show:subreddit:#{subreddit}", length(new_stack) == 1, post_after == "")
          back_data = case subreddit do
                        "_front" -> "show:mainmenu"
                        s -> "show:subreddits:show:#{s}"
                      end

          bottom = [[[text: "Back", callback_data: back_data]]]

          kboard = (arrows ++ bottom) |> create_inline

          case edit :inline, msg, text, parse_mode: "Markdown", reply_markup: kboard, bot: name do
            {:ok, %{resp_body: %{"ok" => false}}} ->
              edit :inline, msg, "Can't decode this post sorry", reply_markup: kboard, bot: name
            _ -> :t
          end
        else
          e -> Logger.error "Can't decode post #{inspect e}"
        end

      end
    end
  end
end
