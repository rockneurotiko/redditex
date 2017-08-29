defmodule Utils do
  use Telex.Dsl

  require Logger

  def sub_after({:ok, js}), do: sub_after(js)
  def sub_after(%{"data" => %{"after" => aafter}}), do: aafter
  def sub_after(_), do: ""

  def stack_list_pop(stack) do
    case String.split(stack, ",") |> List.pop_at(-1) do
      {_, []} -> ""
      {_elem, rest} -> Enum.join(rest, ",")
    end
  end

  def subreddits_names({:ok, js}) do
    case get_in js, ["data", "children", Access.all(), "data", "display_name"] do
      nil -> []
      l ->
        l |> Enum.filter(&(not is_nil(&1)))
    end
  end
  def subreddits_names(_), do: []

  def subreddit_keyboard(subreddit, subscribed) do
    {subs_text, subs_data} = if subscribed, do: {"Unsubscribe", "unsubscribe:#{subreddit}"}, else: {"Subscribe", "subscribe:#{subreddit}"}

    [[[text: "View", callback_data: "show:subreddit:#{subreddit}:page:actual"]],
     [[text: subs_text, callback_data: subs_data]],
     [[text: "Subreddits", callback_data: "show:subreddits:page:actual"]]]
    |> create_inline
  end

  def listing_arrows(prefix, first, last) do
    veryprev = [text: "<<", callback_data: "#{prefix}:page:veryprev"]
    prev = [text: "<", callback_data: "#{prefix}:page:prev"]
    next = [text: ">", callback_data: "#{prefix}:page:next"]

    case {first, last} do
      {true, true} -> [[]]
      {true, _} -> [[next]]
      {_, true} -> [[veryprev, prev]]
      _ -> [[veryprev, prev, next]]
    end
  end

  def list_keyboard(l, prefix, first, last, extra \\ []) do
    bottom_menu = listing_arrows(prefix, first, last)

    data_list = l |> Enum.map(fn {name, data} ->
      [[text: name, callback_data: "#{prefix}:#{data}"]]
    end)

    (data_list ++ bottom_menu ++ extra) |> create_inline
  end
end
