defmodule EmailNotifications.Services.UserService do
  @moduledoc """
  Handles businesss logic related to user operations
  """
  alias EmailNotifications.Models.User
  alias EmailNotifications.Repositories.UserRepo
  alias EmailNotifications.Utils.HashUtils

  @allowed_roles ["admin", "frontend"]

  def register_user(attrs) do
    case UserRepo.find_by_email(attrs["email"]) do
      nil ->
        hashed_password = HashUtils.hash_password(attrs["password"])
        user = User.new(Map.put(attrs, "password", hashed_password))

        UserRepo.create_user(user)

      _user -> {:error, "Email already exists"}

    end
  end
  def fetch_user_details(user_id) do
    case UserRepo.get_user_details(user_id) do
      {ok, user_profile} -> {:ok, user_profile}
      {:error, reason} -> {:error, reason}
    end
  end

  def authenticate_user(email, password) do
    user = UserRepo.find_user(%{"email" => email})
    if user && Argon2.verify_pass(password, user["password"]) do
      {:ok, user}
    else
      {:error, :unauthorized}
    end
  end

  # def validate_super_admin(user_id) do
  #   case UserRepo.get_user_by_id(user_id) do
  #     nil -> {:error, "Admin user not found"}
  #     %{"is_super_user" => true} -> :ok
  #     _ -> {:error, "Forbidden: Only superusers can grant or update admin roles"}
  #   end
  # end

  def validate_super_admin(user_id) do
    case UserRepo.get_user_by_id(user_id) do
      {:error, _} -> {:error, "Admin user not found"}
      {:ok, %{"is_super_user" => true}} -> {:ok, "Valid super admin"}
      {:ok, _} -> {:error, "Forbidden: Only superusers can grant or update admin roles"}
    end
  end


  # Grant admin role to the target user
  # def grant_admin_role(target_user_id) do
  #   case UserRepo.get_user_by_id(target_user_id) do
  #     nil -> {:error, "Target user not found"}
  #     %{"name" => name} = _user ->
  #       case UserRepo.update_user_role(target_user_id, "admin") do
  #         {:ok, _} -> {:ok, "User #{name} is now an admin"}
  #         {:error, _} -> {:error, "Failed to update user role"}
  #       end
  #   end
  # end

  # def grant_admin_role(target_user_id) do
  #   case UserRepo.get_user_by_id(target_user_id) do
  #     {:error, _} -> {:error, "Target user not found"}
  #     {:ok, %{"first_name" => first_name}} ->
  #       case UserRepo.update_user_role(target_user_id, "admin", "grant") do
  #         {:ok, _} -> {:ok, "User #{first_name} is now an admin"}
  #         {:error, _} -> {:error, "Failed to update user role "}
  #       end
  #   end
  # end
  def grant_admin_role(target_user_id) do
    case UserRepo.get_user_by_id(target_user_id) do
      {:error, _} -> {:error, "Target user not found"}
      {:ok, %{"first_name" => first_name}} ->
        case UserRepo.update_user_role(target_user_id, "admin", "grant") do
          {:ok, _} -> {:ok, "User #{first_name} is now an admin"}
          {:error, reason} -> {:error, "Failed to update user role: #{reason}"}
        end
    end
  end



  # Validate the new role
  def validate_new_role(new_role) do
    if new_role in @allowed_roles do
      :ok
    else
      {:error, "Bad Request: Invalid role provided"}
    end
  end

  # Prevent self-demotion
  def prevent_self_demotion(admin_user_id, target_user_id, new_role) do
    if admin_user_id == target_user_id and new_role != "admin" do
      {:error, "Forbidden: You cannot revoke your own admin role"}
    else
      :ok
    end
  end

  # Grant or revoke roles for a user
  def update_user_role(target_user_id) do

    case UserRepo.get_user_by_id(target_user_id) do
      {:error, _} -> {:error, "Target user not found"}
      {:ok, %{"first_name" => first_name}} ->
        case UserRepo.update_user_role(target_user_id, "admin", "revoke") do
          {:ok, _} -> {:ok, "admin role revoked successfully for #{first_name}"}
          {:error, reason} -> {:error, "Failed to update user role: #{reason}"}
        end
    end
  end

  # Validate user role
  def validate_admin_role(user_role) do
    if user_role == "admin" do
      :ok
    else
      {:error, "Forbidden: Only admin users can access this endpoint"}
    end
  end

  # Fetch users and their emails
  def fetch_users_with_emails do
    case UserRepo.get_users_with_emails() do
      [] -> {:error, "No users found"}
      users -> {:ok, users}
    end
  end

  def upgrade_user(user_id) do
    UserRepo.get_user_by_id(user_id)
    |> case do
      {:ok, user} -> UserRepo.update_user(user_id, %{"plan" => "gold"})
      {:error, _} -> {:error, :user_not_found}
    end
  end

  def downgrade_user(user_id) do
    UserRepo.get_user_by_id(user_id)
    |> case do
      {:ok, user} -> UserRepo.update_user(user_id, %{"plan" => "free"})
      {:error, _} -> {:error, :user_not_found}
    end
  end

  def add_admin(user_id) do
    UserRepo.get_user_by_id(user_id)
    |> case do
      {:ok, user} -> UserRepo.add_admin(user_id)
      {:error, _} -> {:error, :user_not_found}
    end
  end

  def revoke_admin(user_id) do
    UserRepo.get_user_by_id(user_id)
    |> case do
      {:ok, user} -> UserRepo.revoke_admin(user_id)
      {:error, _} -> {:error, :user_not_found}
    end
  end

  def make_superuser(user_id) do
    UserRepo.get_user_by_id(user_id)
    |> case do
      {:ok, user} -> UserRepo.toggle_super_user(user_id, true)
      {:error, _} -> {:error, :user_not_found}
    end
  end

  def revoke_superuser(user_id) do
    UserRepo.get_user_by_id(user_id)
    |> case do
      {:ok, user} -> UserRepo.toggle_super_user(user_id, false)
      {:error, _} -> {:error, :user_not_found}
    end
  end


end
