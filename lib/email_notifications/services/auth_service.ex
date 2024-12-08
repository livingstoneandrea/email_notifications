defmodule EmailNotifications.Services.AuthService do
  @moduledoc """
  Handles authentication related operations
  """
  alias EmailNotifications.Repositories.UserRepo
  alias EmailNotifications.Utils.HashUtils
  alias EmailNotifications.Auth.JwtAuth
  require Logger

  def authenticate_user(email, password, login_type \\ nil) do
    case UserRepo.find_user(%{"email" => email}) do
      nil ->
        {:error, "Invalid email or password"}

      user when is_map(user) ->
        hashed_password = Map.get(user, "password")
        roles = Map.get(user, "role", [])

        if hashed_password && HashUtils.verify_password(password, hashed_password) do
          case resolve_role(roles, login_type) do
            {:ok, role} ->
              case generate_token(user["_id"], email, role) do
                token when is_binary(token) -> {:ok, %{token: token, user: user}}
                _ -> {:error, "Failed to generate token"}
              end

            {:error, reason} -> {:error, reason}
          end
        else
          {:error, "Invalid email or password"}
        end

      unexpected ->
        Logger.error("Unexpected user data format: #{inspect(unexpected)}")
        {:error, "Unexpected error"}
    end
  end


  # defp resolve_role(user_roles, nil), do: {:ok, "frontend"} # Default role
  # defp resolve_role(user_roles, login_type) do
  #   if login_type in user_roles do
  #     {:ok, login_type}
  #   else
  #     {:error, "Access denied: Role '#{login_type}' is not assigned to the user"}
  #   end
  # end
  def resolve_role(roles, login_type) do
    cond do
      is_nil(login_type) ->
        {:ok, "frontend"} # Default role

      login_type in roles ->
        {:ok, login_type}

      true ->
        {:error, "Access denied: Role '#{login_type}' is not assigned to the user"}
    end
  end


  defp generate_token(user_id, email, role) do
    claims = %{
      "id" => to_string(user_id),
      "email" => email,
      "role" => role
    }

    Logger.debug "Var value: #{inspect(claims)}"

    case JwtAuth.generate_and_sign_token(claims) do
      {:ok, token} -> token
      {:error, _reason} -> raise "Error generating token"
    end
  end


end
