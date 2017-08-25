defmodule Reditex.AuthMiddleware do

  def auth_response(%{"access_token" => token, "expires_in" => exp, "refresh_token" => refresh_token} = s, uid) do
    exp_time = Timex.now |> Timex.shift(seconds: exp) |> Timex.to_unix

    Mongito.save_auth(uid, token, exp_time, refresh_token)

    s
  end

  def apply(%{update: u, uid: uid} = s) do
    case Mongito.get_auth(uid) do
      {:ok, %{"token" => token, "exp" => exp, "refresh_token" => refresh}} ->
        expt = Timex.from_unix(exp) |> Timex.shift(seconds: -20)
        now = Timex.now

        if Timex.before?(expt, now) do
          case RedditApi.access_token(refresh, true) do
            {:ok, %{"token" => ntoken} = s} ->
              auth_response(s, uid)
              {:ok, Map.put(s, :token, ntoken)}
            _ ->
              {:ok, Map.put(s, :error, :auth)}
          end
        else
          {:ok, Map.put(s, :token, token)}
        end
      _ ->
        {:ok, Map.put(s, :error, :auth)}
    end
  end
end
