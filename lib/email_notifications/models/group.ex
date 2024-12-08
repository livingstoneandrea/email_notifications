defmodule EmailNotifications.Models.Group do
  @moduledoc """
  Define the Group schema
  """

  use TypedStruct

  typedstruct do
    field :_id, BSON.ObjectId.t()
    field :group_name, String.t(), enforce: true
    field :owner, BSON.ObjectId.t(), enforce: true
    field :contacts, list(BSON.ObjectId.t()), default: []
    field :email_status, %{
      sent: non_neg_integer(),
      pending: non_neg_integer(),
      failed: [%{email: String.t(), reason: String.t()}]
    }, default: %{sent: 0, pending: 0, failed: []}
    field :created_at, DateTime.t(), default: DateTime.utc_now()
    field :updated_at, DateTime.t(), default: DateTime.utc_now()
  end
end
