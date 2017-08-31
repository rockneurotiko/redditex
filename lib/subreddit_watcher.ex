defmodule SubredditWatcher do
  require Logger

  @name :reditex
  @timeout 15 * 60 * 1_000          # 15 minutos

  def start_watcher(subreddit) do
    case Registry.lookup(Registry.Subreddits, subreddit) do
      [{pid, _}] ->
        pid
      [] ->
        Logger.info "Creating subreddit watcher for #{subreddit}"
        {:ok, pid} = SubredditWatcher.start_link(Registry.Subreddits, subreddit)
        pid
    end
  end

  def create_initials() do
    Mongito.get_subscriptions() |> Enum.map(&start_watcher/1)
  end

  def start_link(registry, key) do
    GenServer.start_link(__MODULE__, {:ok, key}, name: {:via, Registry, {registry, key}})
  end

  def init({:ok, subreddit}) do
    # Put in useds all right now!
    initial_set =
      with [u|_] <- Mongito.get_users_subscribed(subreddit),
           {:ok, token} <- Auth.get_auth(u),
           {:ok, data} <- RedditApi.subreddit_posts(subreddit, token, limit: 100) do

        useds = get_in data, ["data", "children", Access.all(), "data", "name"]
        MapSet.new(useds)
      else
        _ ->
          MapSet.new()
      end

    t = timer(self())

    {:ok, {subreddit, t, initial_set}}
  end

  defp timer(pid, tick \\ @timeout, t \\ nil) do
    if not is_nil(t) do
      Process.cancel_timer(t)
    end
    Process.send_after(pid, :tick, tick)
  end

  def send_data_post(%{"type" => "image"} = post, u) do
    Logger.warn "TODO"
    case Post.post_to_text(post) do
      {:ok, text} ->
        Telex.send_message u, text, parse_mode: "Markdown", bot: @name
      _ ->
        :err
    end
  end

  def send_data_post(%{"type" => "rich:video"} = post, u) do
    Logger.warn "TODO"
    case Post.post_to_text(post) do
      {:ok, text} ->
        Telex.send_message u, text, parse_mode: "Markdown", bot: @name
      _ ->
        :err
    end
  end

  def send_data_post(%{"type" => "video"} = post, u) do
    Logger.warn "TODO"
    case Post.post_to_text(post) do
      {:ok, text} ->
        Telex.send_message u, text, parse_mode: "Markdown", bot: @name
      _ ->
        :err
    end
  end

  def send_data_post(%{"type" => "self"} = post, u) do
    case Post.post_to_text(post) do
      {:ok, text} ->
        Telex.send_message u, text, parse_mode: "Markdown", bot: @name
      _ ->
        :err
    end
  end

  def send_data_post(%{"type" => "link"} = post, u) do
    case Post.post_to_text(post) do
      {:ok, text} ->
        Telex.send_message u, text, parse_mode: "Markdown", bot: @name
      _ ->
        :err
    end
  end

  def send_data_post(%{"type" => "url"} = post, u) do
    case Post.post_to_text(post) do
      {:ok, text} ->
        Telex.send_message u, text, parse_mode: "Markdown", bot: @name
      _ ->
        :err
    end
  end

  def send_data_post(%{"type" => t} = post, _u) do
    Logger.error "Unknown post type: #{inspect t}, post: #{inspect post}"
  end

  def send_post(post, users) do
    with {:ok, data} <- Post.extract_post_data(post) do
      users |> Enum.map(fn u -> spawn fn -> send_data_post(data, u) end end)
    end
  end

  def send_posts(subreddit, [u|_] = users, used) do
    with {:ok, token} <- Auth.get_auth(u),
         {:ok, data} <- RedditApi.subreddit_posts(subreddit, token, limit: 100) do

      posts = get_in data, ["data", "children", Access.all()]

      Logger.info "Useds: #{inspect used}"

      posts
      |> Enum.filter(fn p -> ! MapSet.member?(used, get_in(p, ["data", "name"])) end)
      |> Enum.map(&(send_post(&1, users)))

      Enum.map(posts, &(get_in &1, ["data", "name"])) |> MapSet.new()
    else
    _ -> MapSet.new()
    end
  end

  def handle_info(:tick, {subreddit, _t, useds}) do
    Logger.info "Fetching subreddit #{subreddit}"
    t = timer(self())

    # First check fetch subscribers, if no subscribers end!
    case Mongito.get_users_subscribed(subreddit) do
      [] ->
        Process.cancel_timer(t)
        {:stop, :normal, {subreddit, nil, useds}}
      users ->
        new_useds = send_posts(subreddit, users, useds)
        {:noreply, {subreddit, t, new_useds}}
    end
  end
end
