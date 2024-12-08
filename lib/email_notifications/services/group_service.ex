defmodule EmailNotifications.Services.GroupService do
  @moduledoc """
  Business logic for managing groups
  """
  alias EmailNotifications.Repositories.GroupRepo
  alias EmailNotifications.Repositories.UserRepo
  alias EmailNotifications.Repositories.ContactRepo

  require Logger

  def create_group(user_id, group_name, contacts) do
    # Perform necessary validations (e.g., user plan, valid contacts)
    with {:ok, _} <- validate_user_plan(user_id),
         {:ok, valid_contacts} <- validate_contacts(user_id, contacts),
         {:ok, _group} <- insert_group(user_id, group_name, valid_contacts) do
      {:ok, "Group created successfully"}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def add_contacts_to_group(user_id,group_id, contact_ids) do
    with {:ok, user} <- UserRepo.get_user_by_id(user_id),
         {:ok, _} <- validate_user_plan(user["_id"]),
         {:ok, group} <- GroupRepo.get_group_by_id(group_id),
         :ok <- validate_user_permission(user, group),
         {:ok, contacts} <- ContactRepo.get_contacts_by_ids(contact_ids, user_id),
         :ok <- update_group_contacts(group, contacts, contact_ids) do
      {:ok, "Contacts added to group successfully"}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_user_plan(user_id) do
    Logger.debug "passed user _id value: #{inspect(user_id)}"
    case UserRepo.get_user_plan(user_id) do
      {:ok, "gold"} -> {:ok, :valid_plan}
      {:ok, _plan} -> {:error, "Only users with the 'gold' plan can create groups"}
      {:error, reason} -> {:error, "Unable to validate user plan: #{reason}"}
    end
  end

  defp validate_contacts(user_id, contact_ids) do
    contacts = GroupRepo.find_contacts(contact_ids, user_id)

    if length(contacts) == length(contact_ids) do
      {:ok, contact_ids}
    else
      {:error, "Some contacts are invalid or do not belong to the user"}
    end
  end

  defp insert_group(owner_id, group_name, contact_ids) do
    group_attrs = %{
      "group_name" => group_name,
      "owner" => owner_id,
      "contacts" => contact_ids,
      "email_status" => %{sent: 0, pending: 0, failed: []},
      "created_at" => DateTime.utc_now(),
      "updated_at" => DateTime.utc_now()
    }

    case GroupRepo.create_group(group_attrs) do
      {:ok, _result} -> {:ok, group_attrs}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_user_permission(user, group) do
    if group["owner"] == user["_id"], do: :ok, else: {:error, "Unauthorized access"}
  end

  
  defp update_group_contacts(group, _contacts, contact_ids) do
    # Convert all contact_ids to BSON ObjectId
    bson_contact_ids =
      contact_ids
      |> Enum.map(&ensure_bson_object_id/1)
      |> Enum.reject(&is_nil/1) # Reject nil values in case of invalid ObjectIds

    # Ensure uniqueness by merging with existing contacts
    new_contacts =
      [group["contacts"] | bson_contact_ids]
      |> List.flatten()
      |> Enum.uniq()

    # Update the group with new contacts
    case GroupRepo.update_group(group["_id"], %{contacts: new_contacts}) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_bson_object_id(contact_id) when is_binary(contact_id) do
    try do
      BSON.ObjectId.decode!(contact_id)
    rescue
      _ ->
        Logger.warn("Invalid ObjectId: #{inspect(contact_id)}")
        nil
    end
  end

  defp ensure_bson_object_id(%BSON.ObjectId{} = contact_id), do: contact_id
  defp ensure_bson_object_id(_), do: nil
end
