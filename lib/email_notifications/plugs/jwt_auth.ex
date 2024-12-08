defmodule EmailNotifications.Plugs.JwtAuth do
  @moduledoc """
  plug to authenticate requests using JWT
  """

  import Plug.Conn
  alias EmailNotifications.Auth.JwtAuth

  def init(default), do: default

  def call(conn, _opts) do
    # Extract the Authorization header
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- JwtAuth.verify_token(token) do
      # Check expiration
      if token_expired?(claims) do
        conn
        |> send_resp(:unauthorized, Jason.encode!(%{error: "Token expired"}))
        |> halt()
      else
        # Add user ID and role to connection assigns
        conn
        |> assign(:user_id, claims["id"])
        |> assign(:user_role, claims["role"])
      end
    else
      :error ->
        conn
        |> send_resp(:unauthorized, Jason.encode!(%{error: "Unauthorized"}))
        |> halt()

      {:error, reason} ->
        conn
        |> send_resp(:unauthorized, Jason.encode!(%{error: "Authentication failed: #{reason}"}))
        |> halt()
    end
  end

  # Check if the token has expired based on the "exp" claim
  defp token_expired?(claims) do
    case Map.get(claims, "exp") do
      exp when is_integer(exp) ->
        exp < System.system_time(:second)

      _ ->
        false
    end
  end


end
