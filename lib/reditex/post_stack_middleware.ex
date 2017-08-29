defmodule Reditex.PostStackMiddleware do
  @regex ~r/show:subreddit:([^:]+):.+/

  def apply(%{uid: uid, update: u} = s) do
    # Extract cbdata
    cbdata = case u do
               %{callback_query: %{data: cbdata}} -> cbdata
               _ -> ""
             end

    case Regex.run(@regex, cbdata) do
      [_, subreddit] ->
        stack =
          case Mongito.get_post_stack(uid, subreddit) do
            %{"stack" => stack} -> stack
            _ -> []
          end
        {:ok, Map.put(s, :post_stack, stack)}
      _ -> {:ok, s}
    end
  end
end
