defmodule EmailNotifications.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EmailNotificationsWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:email_notifications, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EmailNotifications.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: EmailNotifications.Finch},
      # Start a worker by calling: EmailNotifications.Worker.start_link(arg)
      # {EmailNotifications.Worker, arg},
      # Start to serve requests, typically the last entry
      EmailNotificationsWeb.Endpoint,

      # Start the MongoClient
      EmailNotifications.MongoClient,


      # Start the EXQ supervisor
      Exq,

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EmailNotifications.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EmailNotificationsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
