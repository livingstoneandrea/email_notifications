# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :email_notifications,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :email_notifications, EmailNotificationsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: EmailNotificationsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EmailNotifications.PubSub,
  live_view: [signing_salt: "sqszXn+M"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :email_notifications, EmailNotifications.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# mongodb config
config :email_notifications, EmailNotifications.MongoClient,
  url: "mongodb+srv://livin:mEcmADeAJG1koPQX@elixirapp.zieod.mongodb.net/email_notifications?retryWrites=true&w=majority&appName=elixirapp",
  pool_size: 10

config :email_notifications, :mongo_opts,
  ssl: false,
  ssl_opts: [
    verify: :verify_none
  ]

config :mongodb_driver,
  decoder: BSON.PreserveOrderDecoder

config :email_notifications, :jwt_secret, System.get_env("JWT_SECRET") || "default_secret"

#Configure Exq for priority queuing


config :exq,
  start_on_application: false,
  host: "127.0.0.1",
  port: 6379,
  namespace: "exq",
  concurrency: 1000,
  queues: [{"high", 10}, {"normal", 5}, {"low", 2}]




# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
