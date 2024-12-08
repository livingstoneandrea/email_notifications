defmodule EmailNotificationsWeb.GroupController do
  use EmailNotificationsWeb, :controller

  alias EmailNotifications.Services.GroupService

  def create(conn, %{"group_name"=> group_name, "contacts"=> contacts}) do
    # user_id = conn.assigns[:user_id]
    owner_id = get_owner_id(conn)

    if owner_id == nil do
      conn
      |> put_status(:unauthorize)
      |> json(%{message: "Unauthorized"})
    else
      case GroupService.create_group(owner_id, group_name, contacts) do
        {:ok, message} ->
          conn
          |> put_status(:created)
          |>json(%{message: message})

        {:error, reason} ->
          conn
          |> put_status(:forbidden)
          |>json(%{error: reason})

      end
    end
  end

  def add_contacts(conn, %{"group_id" => group_id, "contact_ids" => contact_ids}) do
    user_id = conn.assigns[:user_id]

    if user_id do
      case GroupService.add_contacts_to_group(user_id, group_id, contact_ids) do
        {:ok, message} ->
          json(conn, %{message: message})
        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: reason})
      end
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    end
  end


  defp get_owner_id(conn) do
    conn.assigns[:user_id]
    |> case do
      nil -> nil
      id -> BSON.ObjectId.decode!(id)
    end
  end
end
