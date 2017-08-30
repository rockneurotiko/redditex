defmodule Post do
  require Logger

  def extract_first_post(data) do
    elems = data |> get_in(["data", "children", Access.all()]) |> Enum.filter(&(! get_in &1, ["data", "stickied"] )) |> Enum.take(1)
    case elems do
      [] -> :error
      [x|_] -> {:ok, x}
    end
  end

  defp extract_metadata(%{"permalink" => permalink, "ups" => ups, "title" => title, "author" => author, "subreddit_name_prefixed" => subreddit_name}) do
    %{"permalink" => permalink, "ups" => ups, "title" => title, "author" => author, "subreddit" => String.slice(subreddit_name, 2..-1)}
  end
  defp extract_metadata(_data), do: %{}


  def extract_post_data(%{"kind" => "t3", "data" => data}) do
    metadata = extract_metadata(data)
    post = extract_post_kind_data(data)
    {:ok, Map.merge(post, metadata)}
  end

  defp extract_post_kind_data(%{"url" => url, "is_self" => true, "selftext" => text}) do
    %{"type" => "self", "url" => url, "text" => text}
  end
  defp extract_post_kind_data(%{"url" => url} = data) do
    hint = Map.get(data, "post_hint", "url")
    %{"type" => "url", "url" => url}
  end
  defp extract_post_kind_data(_), do: %{}


  defp escape(t) do
    t
    |> String.replace("*", "\\*")
    |> String.replace("_", "\\_")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
    |> String.replace("[", "\\[")
    |> String.replace("]", "\\]")
  end

  def post_to_text(%{"type" => typ, "url" => url, "permalink" => perma, "ups" => ups, "title" => title, "author" => author, "subreddit" => subreddit} = post) do
    t = Map.get(post, "text", "") |> escape

    header = "[#{title}](#{url})\n#{t}\n"
    bottom = "----\n[<#{typ} by #{author} in #{subreddit} (↑ #{ups})>](https://reddit.com#{perma})"

    diff = (String.length(header) + String.length(bottom)) - 4096

    header = String.slice(header, 0, String.length(header) - diff)

    Logger.info header <> bottom

    {:ok, header <> bottom}
  end
  def post_to_text(e), do: {:error, :post_to_text, e}
end
