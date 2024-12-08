defmodule EmailNotificationsWeb.AuthController do
  use EmailNotificationsWeb, :controller
  alias EmailNotifications.Services.AuthService

  require Logger

  def login(conn, %{"email" => email, "password" => password, "loginType" => login_type }) do
    case AuthService.authenticate_user(email, password, login_type) do
      {:ok, %{token: token, user: user}} ->
        Logger.debug "Var value: #{inspect(token)}"
        json(conn, %{message: "Login successful", token: token, user: user})

      {:error, error} ->
        conn
        |> put_status(:unauthorize)
        |> json(%{message: error})

    end
  end
end
