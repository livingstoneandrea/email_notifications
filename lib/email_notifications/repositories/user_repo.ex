defmodule EmailNotifications.Repositories.UserRepo do
  @moduledoc """
  Handles database operations for User model
  """

  alias EmailNotifications.MongoClient

  require Logger


  @collection "users"
  @email_collection "emails"

  def create_user(attrs) do
    conn = MongoClient.get_connection()
    attrs = Map.merge(attrs, %{inserted_at: DateTime.utc_now()})

    Mongo.insert_one(conn, @collection, Map.from_struct(attrs))

  end

  def find_by_email(email) do
    conn = MongoClient.get_connection()
    Mongo.find_one(conn, @collection, %{email: email})
  end

  def get_user_by_id(user_id) do
    conn = MongoClient.get_connection()
    query = %{_id: BSON.ObjectId.decode!(user_id)}

    case Mongo.find_one(conn, @collection, query) do
      nil -> {:error, "User not found"}
      user -> {:ok, sanitize_user(user)}
    end
  end

  def find_user(query) do
    conn = MongoClient.get_connection()
    Mongo.find_one(conn, @collection, query)
    |> sanitize_user()
  end

  def get_user_plan(user_id) do
    conn = MongoClient.get_connection()

    # query = %{_id: BSON.ObjectId.encode!(user_id)}
    query = %{"_id" => user_id}

    Logger.debug "repo user _id value: #{inspect(query)}"
    case Mongo.find_one(conn, @collection, query) do
      nil -> {:error, "User not found"}
      %{"plan" => plan} -> {:ok, plan}
      _ -> {:error, "Plan information is missing"}
    end
  end

  # def get_users_emails_by_ids(user_ids) do
  #   conn = MongoClient.get_connection()
  #   Mongo.find(conn, @collection, %{"_id" => %{"$in" => user_ids}}, %{projection: %{"email" => 1, "_id" => 0}})
  # end

  def get_users_emails_by_ids(user_ids) do
    conn = MongoClient.get_connection()
    options = [projection: %{"email" => 1, "_id" => 0}] # Use a keyword list
    Mongo.find(conn, @collection, %{"_id" => %{"$in" => user_ids}}, options)
  end



  def update_user(id, updates) do
    conn = MongoClient.get_connection()
    Mongo.update_one(conn, @collection, %{"_id" => id}, %{"$set" => updates})
  end

  def get_user_details(user_id) do
    user_id
    |> to_object_id()
    |> fetch_user_profile()
  end

  defp to_object_id(user_id) do
    BSON.ObjectId.decode!(user_id)
  end

  defp fetch_user_profile(user_id) do
    conn = MongoClient.get_connection()

    pipeline = [
      %{"$match" => %{"_id" => user_id}},
      %{"$lookup" => %{"from" => "emails", "localField" => "_id", "foreignField" => "sender", "as" => "emails"}},
      %{"$lookup" => %{"from" => "groups", "localField" => "_id", "foreignField" => "owner", "as" => "groups"}},
      %{"$lookup" => %{"from" => "contacts", "localField" => "_id", "foreignField" => "user_id", "as" => "contacts"}},
      %{"$project" => %{"_id" => 1, "name" => 1, "email" => 1, "first_name" => 1, "last_name" => 1, "msisdn" => 1, "role" => 1, "plan" => 1, "emails" => 1, "groups" => 1, "contacts" => 1}}
    ]

    conn
    |> Mongo.aggregate("users", pipeline)
    |> Enum.to_list()
    |> case do
      [] -> {:error, "User not found"}
      [user_profile] -> {:ok, user_profile}
    end
  end


  # Update a user's role
  # def update_user_role(user_id, role) do
  #   conn = MongoClient.get_connection()

  #   Mongo.update_one(conn, @collection, %{"_id" => BSON.ObjectId.decode!(user_id)}, %{"$set" => %{"role" => role}})

  # end


  def update_user_role(user_id, role, action) do
    conn = MongoClient.get_connection()

    # Build the query and update operation based on the action (grant or revoke)
    update_op =
      case action do
        "grant" -> %{"$addToSet" => %{"role" => role}}  # Push role to the array
        "revoke" -> %{"$pull" => %{"role" => role}}    # Remove role from the array
        _ -> %{}  # No operation for invalid actions
      end

    # Perform the update
    result = Mongo.update_one(conn, @collection, %{"_id" => BSON.ObjectId.decode!(user_id)}, update_op)

    case result do
      {:ok, %{matched_count: 1, modified_count: 1}} -> {:ok, "User role updated successfully"}
      {:ok, %{matched_count: 1, modified_count: 0}} -> {:error, "No changes made to the user role"}
      {:error, reason} -> {:error, "Failed to update user role: #{reason}"}
    end
  end


   # Fetch users with their sent emails
  def get_users_with_emails do
    conn = MongoClient.get_connection()

    conn
    |> Mongo.aggregate(@collection, [
      %{"$lookup" => %{"from" => @email_collection, "localField" => "_id", "foreignField" => "sender", "as" => "sentEmails"}},
      %{"$project" => %{"_id" => 1, "name" => 1, "email" => 1, "role" => 1, "sentEmails" => %{"recipient" => 1, "subject" => 1, "body" => 1, "status" => 1, "createdAt" => 1}}}
    ])
    |> Enum.to_list()
  end




  defp sanitize_user(nil), do: nil

  defp sanitize_user(user) when is_map(user) do
    Map.drop(user, [:__order__])
    # |> sanitize_id()
  end

  defp sanitize_id(user) do
    case Map.get(user, "_id") do
      %BSON.ObjectId{} = id ->
        Map.put(user, "_id", BSON.ObjectId.encode!(id))
      _ -> user
    end
  end
end
