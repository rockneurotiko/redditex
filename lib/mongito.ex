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

  def get_auth(uid) do
    case Mongo.find_one(:mongo, "auths", %{"uid" => uid}, pool: DBConnection.Poolboy) do
      nil -> :error
      auth -> {:ok, auth}
    end
  end

  def save_auth(uid, token, exp, refresh) do
    Mongo.insert_one(:mongo, "auths", %{"uid" => uid, "token" => token, "exp" => exp, "refresh_token" => refresh}, pool: DBConnection.Poolboy)
  end
end
