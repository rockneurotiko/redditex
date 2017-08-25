defmodule Utils do
  def subreddits_names({:ok, js}) do
    case get_in js, ["data", "children", Access.all(), "data", "display_name"] do
      nil -> []
      l ->
        l |> Enum.filter(&(not is_nil(&1)))
    end
  end
  def subreddits_names(_), do: []
end
