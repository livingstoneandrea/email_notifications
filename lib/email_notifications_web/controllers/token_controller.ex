defmodule EmailNotificationsWeb.TokenController do
  use EmailNotificationsWeb, :controller
  alias EmailNotifications.Auth.JwtAuth

  def login(conn, %{"token" => token}) do

    case JwtAuth.verify_token(token) do
      {:ok, claims} -> json(conn, %{message: "Token is valid", claims: claims})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid token", details: reason})


    end
  end
end
