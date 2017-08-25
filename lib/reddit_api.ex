defmodule RedditApi do

  require Logger

  @base "https://www.reddit.com/api/v1"
  @oauthbase "https://oauth.reddit.com"

  def clean_path(path), do: if String.starts_with?(path, "/"), do: path, else: "/#{path}"
  def uri(path, base \\ @oauthbase), do: "#{base}#{clean_path(path)}"

  def auth(token), do: ["Authorization": "Bearer #{token}"]

  def initial_authorize_url(uid) do
    url = uri("/authorize", @base)
    cid = Telex.Config.get(:reditex, :reddit_client, "")

    "#{url}?client_id=#{cid}&response_type=code&state=#{uid}&redirect_uri=http://127.0.0.1:8080/authorize_callback&duration=permanent&scope=identity mysubreddits read wikiread" |> URI.encode
  end

  def access_token(code, refresh \\ false) do
    url = uri("/access_token", @base)
    cid = Telex.Config.get(:reditex, :reddit_client, "")
    sid = Telex.Config.get(:reditex, :reddit_token, "")
    auth = "#{cid}:#{sid}"

    headers = ["Authorization": "Basic #{Base.url_encode64(auth)}"]

    body = if refresh do
      [grant_type: "refresh_token", refresh_token: code]
    else
      [grant_type: "authorization_code", code: code, redirect_uri: "http://127.0.0.1:8080/authorize_callback"]
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

  def me(token) do
    url = uri("/me")
    headers = auth(token)

    HTTPoison.get(url, headers) |> to_json
  end

  def subreddits(token, ops \\ []) do

    limit = Keyword.get(ops, :limit, 25)
    count = Keyword.get(ops, :count, 0)
    before = Keyword.get(ops, :before, "")
    aafter = Keyword.get(ops, :after, "")
    show = Keyword.get(ops, :show, "all")
    where = Keyword.get(ops, :where, "subscriber")

    url = uri("/subreddits/mine/#{where}?show=#{show}&limit=#{limit}&count=#{count}&before=#{before}&after=#{aafter}")
    headers = auth(token)

    HTTPoison.get(url, headers) |> to_json
  end
end