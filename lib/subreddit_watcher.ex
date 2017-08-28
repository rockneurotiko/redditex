defmodule SubredditWatcher do
  require Logger

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
    t = timer(self())

    {:ok, {subreddit, t}}
  end

  defp timer(pid, tick \\ @timeout, t \\ nil) do
    if not is_nil(t) do
      Process.cancel_timer(t)
    end
    Process.send_after(pid, :tick, tick)
  end

  def handle_info(:tick, {subreddit, _t}) do
    Logger.info "Fetching subreddit #{subreddit}"
    t = timer(self())

    # First check fetch subscribers, if no subscribers end!
    # TODO fetch subreddit posts and send :)
    # Remember to cache after the first send

    {:noreply, {subreddit, t}}
  end

end
