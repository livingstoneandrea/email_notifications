defmodule EmailNotifications.MixProject do
  use Mix.Project

  def project do
    [
      app: :email_notifications,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {EmailNotifications.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.17"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_pubsub, "~> 2.1"},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:mongodb_driver, "~> 1.5"}, # MongoDB driver
      # {:jose, "~> 1.11"}, # JWT support
      {:joken, "~> 2.6"},
      {:bamboo, "~> 2.3"}, # Email handling
      # {:bamboo_sendgrid, "~> 2.3"}, # Sendgrid integration
      {:exq, "~> 0.19.0"},
      {:plug_cowboy, "~> 2.7"},
      {:hackney, "~> 1.20"},
      {:argon2_elixir, "~> 3.0"},
      {:typed_struct, "~> 0.1.4"},
      {:cors_plug, "~> 2.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
