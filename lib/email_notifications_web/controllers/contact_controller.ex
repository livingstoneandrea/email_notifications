defmodule EmailNotificationsWeb.ContactController do
  use EmailNotificationsWeb, :controller
  alias EmailNotifications.Services.ContactService

  def create(conn, %{"name"=> name, "email" => email, "phone" => phone}) do
    # user_id = get_req_header(conn, "x-user-id") |> List.first()
    # user_role = get_req_header(conn, "x-user-role") |> List.first()
    user_id = conn.assigns[:user_id]
    user_role = conn.assigns[:user_role]

    if is_nil(user_id) or is_nil(user_role) do
      conn
      |> put_status(:unauthorize)
      |> json(%{message: "Unauthorized"})
    else
      params = %{name: name, email: email, phone: phone}

      case ContactService.add_contact(user_id, user_role, params) do
        {:ok, contact} ->
          conn
          |> put_status(:created)
          |>json(contact)

        {:error, reason} ->
          conn
          |> put_status(:fobidden)
          |>json(%{error: reason})

      end
    end
  end
end
