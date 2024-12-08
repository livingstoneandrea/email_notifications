defmodule EmailNotifications.Services.ContactService do
  @moduledoc """
  Handles businesss logic related to contact operations
  """
  alias EmailNotifications.Repositories.ContactRepo
  alias EmailNotifications.Models.Contact


  def add_contact(user_id, user_role, params) do
    allowed_roles = ["admin", "frontend"]

    if !Enum.member?(allowed_roles, user_role) do
      {:error, "Forbidden: Insufficient permissions"}
    else
      params_with_user = Map.put(params, :user_id, BSON.ObjectId.decode!(user_id))
      case Contact.changeset(params_with_user) do
        {:ok, contact} ->
          ContactRepo.create_contact(contact)

        {:error, error} ->
          {:error, error}
      end
    end
  end

end
