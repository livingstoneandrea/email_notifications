defmodule EmailNotifications.Models.User do
  @moduledoc """
  Define the User schema and default values
  """
  @enforce_keys [:email, :password, :first_name, :last_name, :msisdn]
  # @derive {Jason.Encoder, only: [:email, :first_name, :last_name, :msisdn, :role, :plan, :is_super_user]}

  # @derive Jason.Encoder

  defstruct [
    :email,
    :password,
    :first_name,
    :last_name,
    :msisdn,
    :role,
    :plan,
    :is_super_user
  ]

  @default_role ["frontend"]
  @default_plan "free"
  @default_is_super_user false

  def new(attrs) do
    %__MODULE__{
      email: attrs["email"],
      password: attrs["password"],
      first_name: attrs["first_name"],
      last_name: attrs["last_name"],
      msisdn: attrs["msisdn"],
      role: attrs["role"] || @default_role,
      plan: attrs["plan"] || @default_plan,
      is_super_user: attrs["is_super_user"] || @default_is_super_user
    }
  end

end

# defimpl Jason.Encoder, for: EmailNotifications.Models.User do
#   def encode(%EmailNotifications.Models.User{} = user, opts) do
#     user
#     |> Map.from_struct()
#     |> Map.update(:_id, nil, fn
#       %BSON.ObjectId{} = id -> BSON.ObjectId.encode!(id)
#       other -> other
#     end)
#     |> Jason.Encode.map(opts)
#   end
# end
