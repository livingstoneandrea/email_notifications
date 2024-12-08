defmodule EmailNotifications.Repositories.GroupRepo do
  @moduledoc """
  Handles database operations for Group model
  """
  alias EmailNotifications.MongoClient
  # alias EmailNotifications.Models.Group

  @collection "groups"

  def create_group(group_attrs) do
    conn = MongoClient.get_connection()
    Mongo.insert_one(conn, @collection, group_attrs)
  end

  def find_by_owner(owner_id) do
    conn = MongoClient.get_connection()
    Mongo.find(conn, @collection, %{"owner" => owner_id})
  end

  def find_contacts(contact_ids, owner_id) do
    conn = MongoClient.get_connection()
    Mongo.find(conn, "contacts", %{
      "_id" => %{"$in" => contact_ids},
      "user_id" => owner_id
    })
    |> Enum.to_list()
  end

  def get_group_by_id(group_id) do
    conn = MongoClient.get_connection()
    # query = %{"_id" => BSON.ObjectId.from_string(group_id)}
    query = %{_id: BSON.ObjectId.decode!(group_id)}

    case Mongo.find_one(conn, @collection, query) do
      nil -> {:error, "Group not found"}
      group -> {:ok, group}
    end
  end

  def update_group(group_id, updates) do
    conn = MongoClient.get_connection()

    query = %{_id: group_id}
    # query = %{"_id" => BSON.ObjectId.from_string(group_id)}
    updates = %{"$set" => updates}
    case Mongo.update_one(conn, @collection, query, updates) do
      {:ok, _result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end


end
