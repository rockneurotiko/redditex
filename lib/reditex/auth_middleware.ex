defmodule Reditex.AuthMiddleware do
  def apply(%{update: u, uid: uid} = s) do
    case Auth.get_auth(uid) do
      {:ok, token} ->
        {:ok, Map.put(s, :token, token)}
      _ ->
        {:ok, Map.put(s, :error, :auth)}
    end
  end
end
