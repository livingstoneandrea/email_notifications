defmodule EmailNotifications.Repositories.EmailRepo do
  alias EmailNotifications.MongoClient


  require Logger

  @collection "emails"
  @groups_collection "groups"

  def create_email(attrs) do
    conn = MongoClient.get_connection()
    email = Map.merge(attrs, %{
      # __id: BSON.ObjectId.new(),
      created_at: DateTime.utc_now()
    })

    case Mongo.insert_one(conn, @collection, email) do
      {:ok, result} -> {:ok, Map.put(email, :_id, result.inserted_id)}
      {:error, reason} -> {:error, reason}
    end

  end

  def get_emails_by_user(user_id) do
    conn = MongoClient.get_connection()
    Mongo.find(conn, @collection, %{"from" => user_id}) |> Enum.to_list()
  end

  # Get an email by ID
  def get_email_by_id(email_id) do
    conn = MongoClient.get_connection()
    Logger.info("Getting email by ID: #{email_id}")
    case Mongo.find_one(conn, @collection, %{_id: BSON.ObjectId.decode!(email_id)}) do
      nil -> {:error, :not_found}
      email -> {:ok, email}
    end
  end

  def delete_by_id(email_id) do
    conn = MongoClient.get_connection()
    Mongo.delete_one(conn, @collection, %{"_id" => BSON.ObjectId.decode!(email_id)})
  end

  def find_by_sender(sender_id) do
    conn = MongoClient.get_connection()
    Mongo.find(conn, @collection, %{"sender" => sender_id}, sort: %{"created_at" => -1})
    |> Enum.to_list()
  end
  # Update email status in MongoDB
  def update_email_status(email_id, status, reason \\ nil) do
    conn = MongoClient.get_connection()
    update = if reason do
      %{"$set" => %{status: status, reason: reason}}
    else
      %{"$set" => %{status: status}}
    end

    case Mongo.update_one(conn, @collection, %{_id: BSON.ObjectId.decode!(email_id)}, update) do
      {:ok, _result} -> {:ok, :updated}
      {:error, reason} -> {:error, reason}
    end
  end
  def get_emails_by_recipient(email_list) do
    conn = MongoClient.get_connection()
    Mongo.find(conn, @collection, %{"recipient" => %{"$in" => email_list}})
  end


  def get_group_email_status(group_id, user_id) do
    conn = MongoClient.get_connection()

    Logger.info("Getting email status for group #{group_id} and user #{user_id}")

    # Fetch the group by ID and ensure it belongs to the user
    case Mongo.find_one(conn, @groups_collection, %{
           "_id" => BSON.ObjectId.decode!(group_id),
           "owner" => BSON.ObjectId.decode!(user_id)
         }) do
      nil ->
        {:error, :group_not_found}

      %{"email_status" => %{"failed" => failed_ids, "pending" => pending, "sent" => sent}} ->
      
        failed_contact_ids =
          case failed_ids do
            [] -> []
            ids -> Enum.map(ids, &BSON.ObjectId.decode!/1)
          end

        # Fetch details of failed contacts
        failed_contacts =
          Mongo.find(conn, "contacts", %{"_id" => %{"$in" => failed_contact_ids}})
          |> Enum.to_list()

        {:ok,
         %{
           pending: pending || 0,
           sent: sent || 0,
           failed: failed_contacts
         }}

      %{"email_status" => _} ->
        {:error, :invalid_group_data}

      _ ->
        {:error, :group_not_found}
    end
  end



end
