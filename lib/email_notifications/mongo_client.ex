defmodule EmailNotifications.MongoClient do
  use GenServer

  alias Mongo

  # @mongo_opts Application.get_env(:email_notifications, :mongo_opts)

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, conn} =
      Mongo.start_link(
        url: Application.get_env(:email_notifications, EmailNotifications.MongoClient)[:url],
        pool_size: Application.get_env(:email_notifications, EmailNotifications.MongoClient)[:pool_size],
        ssl_opts: [verify: :verify_none]

      )

    {:ok, conn}
  end

  def get_connection, do: GenServer.call(__MODULE__, :get_conn)

  def handle_call(:get_conn, _from, conn), do: {:reply, conn, conn}
end
