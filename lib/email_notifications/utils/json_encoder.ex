
defimpl Jason.Encoder, for: BSON.ObjectId do
  def encode(val, _opts \\ []) do
    BSON.ObjectId.encode!(val)
    |> Jason.encode!()
  end
end

defimpl Jason.Encoder, for: Mongo.WriteError do
  def encode(%Mongo.WriteError{write_errors: errors} = _error, opts) do
    errors
    |> Enum.map(& &1["errmsg"])
    |> Jason.Encode.list(opts)
  end
end
