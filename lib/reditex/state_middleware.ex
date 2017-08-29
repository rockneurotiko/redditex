defmodule Reditex.StateMiddleware do
  @default %{"stack" => [], "post_stack" => []}

  def apply(%{uid: uid} = s) do
    state = Map.put(@default, "uid", uid)

    case Mongito.get_state(uid, state) do
      {:ok, %{"stack" => stack}} ->
        {:ok, Map.merge(s, %{stack: stack})}
      _ ->
        {:ok, Map.put(s, :error, :state)}
    end
  end
end
