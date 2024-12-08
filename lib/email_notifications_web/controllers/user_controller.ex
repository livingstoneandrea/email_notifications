defmodule EmailNotificationsWeb.UserController do
  @moduledoc """
  Handles incomming requests for User operations
  """
  use EmailNotificationsWeb, :controller
  alias EmailNotifications.Services.UserService


  def register(conn, %{
        "email" => email,
        "password" => password,
        "first_name" => first_name,
        "last_name" => last_name,
        "msisdn" => msisdn,
        # "role" => role,
        # "plan" => plan
      }) do
    attrs = %{
      "email" => email,
      "password" => password,
      "first_name" => first_name,
      "last_name" => last_name,
      "msisdn" => msisdn,
      # "role" => role || ["frontend"],
      # "plan" => plan || "free"
    }

    case UserService.register_user(attrs) do
      {:ok, result} ->
        json(conn, %{message: "User registered successfully", user_id: result.inserted_id})

      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: error})
    end
  end


  def register(conn, %{"email" => email, "password" => password}) do
    case UserService.register_user(%{"email" => email, "password" => password}) do
      {:ok, user} -> json(conn, user)
      {:error, reason} -> send_resp(conn, 400, reason)
    end
  end

  def get_user_profile(conn, _params) do
    user_id = conn.assigns[:user_id]
    case UserService.fetch_user_details(user_id) do
      {:ok, user_profile} ->
        json(conn, %{status: "success", data: user_profile})

      {:error, reason} ->
        json(conn, %{status: "error", message: reason})
    end
  end

  def grant_admin_role(conn, params) do
    super_admin_id = conn.assigns[:user_id]
    super_admin_role = conn.assigns[:user_role]

    # Validate headers
    if is_nil(super_admin_id) or is_nil(super_admin_role) do
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    else
      case super_admin_role do
        "admin" ->
          with {:ok, _} <- UserService.validate_super_admin(super_admin_id),
               {:ok, message} <- UserService.grant_admin_role(params["targetUserId"]) do
            conn
            |> put_status(:ok)
            |> json(%{message: message})
          else
            {:error, reason} ->
              conn
              |> put_status(:forbidden)
              |> json(%{error: reason})
          end

        _ ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden: Only admin users can update roles"})
      end
    end
  end

  def update_user_role(conn, %{"targetUserId" => target_user_id}) do
    admin_user_id = conn.assigns[:user_id]
    admin_user_role = conn.assigns[:user_role]

    # Validate headers
    if is_nil(admin_user_id) or is_nil(admin_user_role) do
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    else
      case admin_user_role do
        "admin" ->
          with {:ok, _} <- UserService.validate_super_admin(admin_user_id),
              #  :ok <- UserService.validate_new_role(new_role),
               :ok <- UserService.prevent_self_demotion(admin_user_id, target_user_id, "admin"),
               {:ok, message} <- UserService.update_user_role(target_user_id) do
            conn
            |> put_status(:ok)
            |> json(%{message: message})
          else
            {:error, reason} ->
              conn
              |> put_status(:forbidden)
              |> json(%{error: reason})
          end

        _ ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden: Only admin users can update roles"})
      end
    end
  end



  def index(conn, _params) do
    user_id = conn.assigns[:user_id]
    user_role = conn.assigns[:user_role]

    # Validate user authentication
    if is_nil(user_id) or is_nil(user_role) do
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    else
      case UserService.validate_admin_role(user_role) do
        :ok ->
          case UserService.fetch_users_with_emails() do
            {:ok, users} ->
              conn
              |> put_status(:ok)
              |> json(users)

            {:error, reason} ->
              conn
              |> put_status(:internal_server_error)
              |> json(%{error: reason})
          end

        {:error, reason} ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: reason})
      end
    end
  end


  # def profile(conn, _params) do
  #   user_id = get_user_id(conn)
  #   user = UserService.get_user_by_id(user_id)
  #   json(conn, user)
  # end

  # defp get_user_id(conn) do
  #   {:ok, claims} = JWTAuth.verify_jwt(get_token(conn))
  #   claims["sub"]
  # end

  # defp get_token(conn), do: get_req_header(conn, "authorization") |> List.first() |> String.replace("Bearer ", "")

end
