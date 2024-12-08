defmodule EmailNotifications.Models.Email do
  @moduledoc """
  Define the Email schema
  """
  use TypedStruct

  typedstruct do
    field :_id, BSON.ObjectId.t()
    field :sender, BSON.ObjectId.t(), enforce: true
    field :recipient, BSON.ObjectId.t(), enforce: true
    field :subject, String.t(), enforce: true
    field :body, String.t(), enforce: true
    field :status, String.t(), default: "pending"
    field :created_at, DateTime.t(), default: DateTime.utc_now()

  end
end
