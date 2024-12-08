defmodule EmailNotifications.Models.Contact do
  @moduledoc """
  Define the Contact schema
  """
  @derive {Jason.Encoder, only: [:user_id, :name, :email, :phone, :creaated_at]}

  defstruct [:user_id, :name, :email, :phone, :creaated_at]

  def changeset(params) do
    %__MODULE__{}
    |> Map.merge(params)
    |> validate()
  end

  defp validate(contact) do
    cond do
      !Map.has_key?(contact, :user_id) -> {:error, "User ID is required"}
      !Map.has_key?(contact, :name) -> {:error, "Name is required"}
      !Map.has_key?(contact, :email) -> {:error, "Email is required"}
      true -> {:ok, contact}
    end
  end

end
