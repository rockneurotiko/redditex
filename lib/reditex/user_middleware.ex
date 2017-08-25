defmodule Reditex.UserMiddleware do
  def apply(%{update: u} = s) do

    with {:ok, %{id: uid} = user} <- Telex.Dsl.extract_user(u),
         {:ok, %{id: gid}} <- Telex.Dsl.extract_group(u),
         {:ok, _} <- Mongito.get_create_user(uid, Map.get(user, :username, Map.get(user, :name, "")))
         # {:ok, _} <- HousePlanner.Db.get_create_group(gid),
         # {:ok, _} <- HousePlanner.Db.user_to_group(uid, gid)
      do

      IO.puts "GROUP: #{gid}, USER: #{uid}"

      {:ok, Map.merge(s, %{gid: gid, uid: uid})}
    else
      e ->
        IO.puts "Error: #{inspect e}"
      {:ok, Map.put(s, :error, :create_user_info)}
    end
  end
  def apply(s), do: {:error, s}
end
