defmodule EmailNotifications.Auth.JwtAuth do
  use Joken.Config

  alias Joken.Signer

  # Define secret and signer
  @secret Application.compile_env(:email_notifications, :jwt_secret, "default_secret")
  @signer Signer.create("HS256", @secret)

  # Function to generate a JWT token
  def generate_and_sign_token(claims) do
    # Add default claims and sign with the configured signer
    token = Joken.Config.default_claims()
              |> Joken.generate_and_sign!(claims, @signer)
    {:ok, token}
  rescue
    e -> {:error, e}
  end

  # Verify the token

  def verify_token(token) do
    # Verify the JWT token using the signer

    case Joken.verify(token, @signer) do
      {:ok, claims} ->
        {:ok, claims}

      {:error, reason} ->
        {:error, format_error(reason)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end




  # Helper function to format errors
  defp format_error(error) do
    cond do
      is_binary(error) -> error
      is_map(error) -> Map.get(error, :message, "An error occurred")
      true -> "Unknown error: #{inspect(error)}"
    end
  end
end
