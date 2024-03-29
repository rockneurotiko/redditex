defmodule RedditApi do
  require Logger

  @base "https://www.reddit.com/api/v1"
  @oauthbase "https://oauth.reddit.com"

  # @redirect_uri "http://127.0.0.1:8080/authorize_callback"
  # @redirect_uri "http://web.neurotiko.com/redirectmereddit"

  def clean_path(path), do: if String.starts_with?(path, "/"), do: path, else: "/#{path}"
  def uri(path, base \\ @oauthbase), do: "#{base}#{clean_path(path)}"

  def auth(token), do: ["Authorization": "Bearer #{token}"]

  def initial_authorize_url(uid) do
    url = uri("/authorize", @base)
    cid = Telex.Config.get(:reditex, :reddit_client, "")

    state = uid

    redirect_uri = Telex.Config.get(:reditex, :redirect_uri)

    "#{url}?client_id=#{cid}&response_type=code&state=#{state}&redirect_uri=#{redirect_uri}&duration=permanent&scope=identity mysubreddits read wikiread" |> URI.encode
  end

  def access_token(code, refresh \\ false) do
    url = uri("/access_token", @base)
    cid = Telex.Config.get(:reditex, :reddit_client, "")
    sid = Telex.Config.get(:reditex, :reddit_token, "")
    auth = "#{cid}:#{sid}"

    headers = ["Authorization": "Basic #{Base.url_encode64(auth)}"]

    redirect_uri = Telex.Config.get(:reditex, :redirect_uri)

    body = if refresh do
      [grant_type: "refresh_token", refresh_token: code]
    else
      [grant_type: "authorization_code", code: code, redirect_uri: redirect_uri]
    end

    with {:ok, %{body: bodys}} <- HTTPoison.post(url, {:form, body}, headers),
         {:ok, body} <- Poison.decode(bodys) do
      {:ok, body}
    else
      _ -> :error
    end
  end

  def to_json({:ok, %{body: body}}), do: {:ok, Poison.decode!(body)}
  def to_json(e), do: e

  def generic(token, u, ops \\ []) do
    params = ops |> Enum.map(fn {k, v} -> "#{k}=#{v}" end) |> Enum.join("&")
    uuri = if String.length(params) == 0, do: u, else: "#{u}?#{params}"

    url = uri(uuri)
    headers = auth(token)

    HTTPoison.get(url, headers) |> to_json
  end

  def me(token) do
    generic(token, "/api/v1/me")
  end

  def subreddits(token, ops \\ []) do
    where = Keyword.get(ops, :where, "subscriber")
    base = [limit: 25, count: 0, before: "", after: "", show: "all"]
    params = Keyword.merge(base, ops)

    generic(token, "/subreddits/mine/#{where}", params)
  end

  def subreddit_posts(subreddit, token, ops \\ [])
  def subreddit_posts("_front", token, ops) do
    base = [g: "GLOBAL"]
    params = Keyword.merge(base, ops)

    generic(token, "/", params)
  end

  def subreddit_posts(subreddit, token, ops) do
    kind = Keyword.get(ops, :kind, "hot")
    base = [g: "GLOBAL"]
    params = Keyword.merge(base, ops)

    generic(token, "/r/#{subreddit}/#{kind}", params)
  end
end
