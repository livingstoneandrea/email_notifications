defmodule EmailNotificationsWeb.EmailController do
  use EmailNotificationsWeb, :controller
  alias EmailNotifications.Services.EmailService

  require Logger

  def send_email(conn, %{"to" => to, "subject" => subject, "body" => body} = params) do
    user_id = conn.assigns[:user_id]
    user_role = conn.assigns[:user_role]

    Logger.debug("user_id: #{user_id}, user_role: #{user_role}")

    if user_id && user_role do
      case EmailService.send_email(user_id, user_role, params) do
        {:ok, email_data} ->
          json(conn, %{status: "success", data: email_data})

        {:error, error_message} ->
          conn
          |> put_status(:bad_request)
          |> json(%{status: "error", message: error_message})

        end
    else
      conn
      |> put_status(:unauthorize)
      |> json(%{status: "error", message: "Unauthorized"})
    end
  end

  def delete_email(conn, %{"email_id" => email_id}) do
    user_id = conn.assigns[:user_id]
    user_role = conn.assigns[:user_role]

    if is_nil(user_id) or is_nil(user_role) do
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    else
      case EmailService.delete_email(email_id, user_id, user_role) do
        {:ok, message} ->
          conn
          |> put_status(:ok)
          |> json(%{message: message})

        {:error, :forbidden, error} ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: error})

        {:error, :unauthorized, error} ->
          conn
          |> put_status(:unauthorized)
          |> json(%{error: error})

        {:error, :not_found, error} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: error})

        {:error, :server_error, error} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: error})
      end
    end
  end

  def emails_history(conn, _params) do
    user_id = conn.assigns[:user_id]
    user_role = conn.assigns[:user_role]

    if is_nil(user_id) or is_nil(user_role) do
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    else
      case EmailService.list_user_emails(user_id, user_role) do
        {:ok, emails} ->
          conn
          |> put_status(:ok)
          |> json(emails)

        {:error, :forbidden, error} ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: error})

        {:error, :not_found, error} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: error})

        {:error, :server_error, error} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: error})
      end
    end
  end

  def retry_email(conn, _params) do
    user_id = conn.assigns[:user_id]
    user_role = conn.assigns[:user_role]

    if is_nil(user_id) or is_nil(user_role) do
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    else
      case conn.body_params do
        %{"emailId" => email_id} ->
          case EmailService.retry_email(user_id, user_role, email_id) do
            {:ok, message} ->
              conn
              |> put_status(:ok)
              |> json(%{message: message})

            {:error, :forbidden, message} ->
              conn
              |> put_status(:forbidden)
              |> json(%{error: message})

            {:error, :not_found, message} ->
              conn
              |> put_status(:not_found)
              |> json(%{error: message})

            {:error, :server_error, message} ->
              conn
              |> put_status(:internal_server_error)
              |> json(%{error: message})
          end

        _ ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Missing emailId"})
      end
    end
  end

  def get_email_status(conn, _params) do
    user_id = conn.assigns[:user_id]

    if is_nil(user_id) do
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    else
      group_id = conn.query_params["groupId"]

      if is_nil(group_id) do
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Bad Request: groupId is required"})
      else
        case EmailService.get_email_status(user_id, group_id) do
          {:ok, status} ->
            conn
            |> put_status(:ok)
            |> json(status)

          {:error, :forbidden, message} ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: message})

          {:error, :not_found, message} ->
            conn
            |> put_status(:not_found)
            |> json(%{error: message})

          {:error, :bad_request, message} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: message})

          {:error, :unauthorized, message} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: message})
        end
      end
    end
  end

  def send_email_to_group(conn, %{"user_id" => user_id, "group_id" => group_id, "email_attrs" => email_attrs}) do
    user_role = conn.assigns[:user_role]

    case EmailService.send_email_to_group(user_id, user_role, group_id, email_attrs) do
      {:ok, inserted_ids} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Emails queued successfully", email_ids: inserted_ids})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def get_group_email_status(conn, %{"group_id" => group_id}) do
    user_id = conn.assigns[:user_id]
    user_role = conn.assigns[:user_role]

    # Fetch the user plan from MongoDB
    case UserRepo.get_user_plan(user_id) do
      {:ok, user_plan} ->
        case EmailService.get_group_email_status(user_id, user_role, user_plan, group_id) do
          {:ok, status} ->
            json(conn, %{status: "success", data: status})

          {:error, reason} ->
            conn
            |> put_status(:forbidden)
            |> json(%{status: "error", message: to_string(reason)})
        end

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{status: "error", message: to_string(reason)})
    end
  end
end
