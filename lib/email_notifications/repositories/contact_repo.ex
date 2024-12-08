defmodule EmailNotifications.Repositories.ContactRepo do
  @moduledoc """
  Handles database operations for Contact model
  """
  alias EmailNotifications.MongoClient

  # alias EmailNotifications.Models.Contact

  require Logger

  @collection "contacts"
  @groups_collection "groups"

  def create_contact(contact) do
    conn = MongoClient.get_connection()
    case Mongo.insert_one(conn, @collection, Map.from_struct(contact)) do
      {:ok, result} ->
        {:ok, Map.put(contact, :id, result.inserted_id)}

      {:error, error} ->
        Logger.error("Failed to insert contact: #{inspect(error)}")
        {:error, "Failed to add contact"}

    end
  end

  def get_contacts_by_ids(contact_ids, user_id) do
    conn = MongoClient.get_connection()

    contact_ids = Enum.map(contact_ids, &BSON.ObjectId.decode!(&1))
    query = %{"_id" => %{"$in" => contact_ids}, "user_id" => BSON.ObjectId.decode!(user_id)}

    case Mongo.find(conn, @collection, query) do
      [] -> {:error, "Some contacts do not exist or do not belong to the user"}
      contacts -> {:ok, contacts}
    end
  end

  def find_contact_by_email(email) do
    conn = MongoClient.get_connection()
    case Mongo.find_one(conn, @collection, %{email: email}) do
      nil -> {:error, :contact_not_found}
      contact -> {:ok, contact}
    end
  end

  def get_contacts_by_group(group_id) do
    conn = MongoClient.get_connection()

    # Find the group document by group_id
    case Mongo.find_one(conn, @groups_collection, %{"_id" => BSON.ObjectId.decode!(group_id)}) do
      nil ->
        {:error, :group_not_found}

      %{"contacts" => contact_ids} ->
        # Decode contact IDs and query the contacts collection
        decoded_contact_ids = Enum.map(contact_ids, &BSON.ObjectId.decode!/1)

        query = %{"_id" => %{"$in" => decoded_contact_ids}}

        case Mongo.find(conn, @collection, query) |> Enum.to_list() do
          [] -> {:error, :contacts_not_found}
          contacts -> {:ok, contacts}
        end

      _ ->
        {:error, :invalid_group_data}
    end
  end
end
