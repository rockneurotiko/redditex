defmodule Mongito do
  def get_create_user(uid, name) do
    find =
      Mongo.find_one(:mongo, "users", %{"uid" => uid}, pool: DBConnection.Poolboy)

    case find do
      nil ->
        Mongo.insert_one(:mongo, "users", %{"uid" => uid, "name" => name}, pool: DBConnection.Poolboy)
      user ->
        {:ok, user}
    end
  end

  # AUTH

  def get_auth(uid) do
    case Mongo.find_one(:mongo, "auths", %{"uid" => uid}, pool: DBConnection.Poolboy) do
      nil -> :error
      auth -> {:ok, auth}
    end
  end

  def save_auth(uid, token, exp, refresh) do
    Mongo.find_one_and_replace(:mongo, "auths", %{"uid" => uid}, %{"uid" => uid, "token" => token, "exp" => exp, "refresh_token" => refresh}, upsert: true, pool: DBConnection.Poolboy)
  end

  # SUBSCRIPTIONS

  def get_subscriptions(uid \\ nil) do
    m = if is_nil(uid), do: %{}, else: %{"uid" => uid}
    Mongo.find(:mongo, "subscriptions", m, projection: %{"subreddit" => 1}, pool: DBConnection.Poolboy) |> Enum.to_list |> Enum.map(&(Map.get(&1, "subreddit"))) |> Enum.uniq
  end

  def subscribed?(uid, subreddit) do
    elem = %{"uid" => uid, "subreddit" => subreddit}
    case Mongo.find_one(:mongo, "subscriptions", elem, pool: DBConnection.Poolboy) do
      nil -> false
      _ -> true
    end
  end

  def save_subscription(uid, subreddit) do
    elem = %{"uid" => uid, "subreddit" => subreddit}

    Mongo.find_one_and_replace(:mongo, "subscriptions", elem, elem, upsert: true, pool: DBConnection.Poolboy)
    Mongo.find_one_and_update(:mongo, "subreddits", %{"subreddit" => subreddit}, %{"$inc" => %{"count" => 1}}, upsert: true, return_document: :after, pool: DBConnection.Poolboy)
  end

  def delete_subscription(uid, subreddit) do
    elem = %{"uid" => uid, "subreddit" => subreddit}

    Mongo.find_one_and_delete(:mongo, "subscriptions", elem, pool: DBConnection.Poolboy)
    Mongo.find_one_and_update(:mongo, "subreddits", %{"subreddit" => subreddit}, %{"$inc" => %{"count" => -1}}, upsert: true, return_document: :after, pool: DBConnection.Poolboy)
  end

  # STATE

  def get_state(uid, default) do
    case Mongo.find_one(:mongo, "states", %{"uid" => uid}, pool: DBConnection.Poolboy) do
      nil ->
        Mongo.insert_one(:mongo, "states", default, pool: DBConnection.Poolboy)
        {:ok, default}
      s -> {:ok, s}
    end
  end

  # STACKT

  def set_stack(uid, stack) do
    Mongo.find_one_and_update(:mongo, "states", %{"uid" => uid}, %{"$set" => %{"stack" => stack}}, pool: DBConnection.Poolboy)
  end

  def set_post_stack(uid, stack) do
    Mongo.find_one_and_update(:mongo, "states", %{"uid" => uid}, %{"$set" => %{"post_stack" => stack}}, pool: DBConnection.Poolboy)
  end
end
