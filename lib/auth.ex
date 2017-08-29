defmodule Auth do
  def auth_response(%{"access_token" => token, "expires_in" => exp, "refresh_token" => refresh_token} = s, uid) do
    exp_time = Timex.now |> Timex.shift(seconds: exp) |> Timex.to_unix

    Mongito.save_auth(uid, token, exp_time, refresh_token)

    s
  end

  def get_auth(uid) do
    case Mongito.get_auth(uid) do
      {:ok, %{"token" => token, "exp" => exp, "refresh_token" => refresh}} ->
        expt = Timex.from_unix(exp) |> Timex.shift(seconds: -20)
        now = Timex.now

        if Timex.before?(expt, now) do
          case RedditApi.access_token(refresh, true) do
            {:ok, %{"access_token" => ntoken} = response} ->
              auth_response(Map.put(response, "refresh_token", refresh), uid)
              {:ok, ntoken}
            _ ->
              :error
          end
        else
          {:ok, token}
        end
      _ ->
        :error
    end
  end
end
