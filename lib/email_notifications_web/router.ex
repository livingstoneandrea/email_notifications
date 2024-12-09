defmodule EmailNotificationsWeb.Router do
  # alias Bamboo.Email
  use EmailNotificationsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :jwt_auth do
    plug EmailNotifications.Plugs.JwtAuth
  end

  scope "/api", EmailNotificationsWeb do
    pipe_through :api

    post "/users/register", UserController, :register

    post "/auth/login", AuthController, :login
    post "/auth/verify_token", TokenController, :login

    scope "/users" do
      pipe_through :jwt_auth

      get "/profile", UserController, :get_user_profile

    end

    scope "/contacts" do
      pipe_through :jwt_auth
      post "/add", ContactController, :create
    end

    scope "/groups" do
      pipe_through :jwt_auth

      post "/create", GroupController, :create
      post "/:group_id/add-contact", GroupController, :add_contacts
    end

    scope "/emails" do
      pipe_through :jwt_auth

      post "/send", EmailController, :send_email
      post "/send-email-to-group", EmailController, :send_email_to_group
      delete "/:email_id", EmailController, :delete_email
      get "/", EmailController, :emails_history
      post "/retry", EmailController, :retry_email
      get "/status", EmailController, :get_group_email_status
    end

    scope "/admin" do
      pipe_through :jwt_auth

      # Admin routes
      patch "/grant-admin", UserController, :grant_admin_role
      patch "/revoke-admin", UserController, :update_user_role
      get "/view-users-with_emails", UserController, :index

      post "/users/:user_id/upgrade", UserController, :upgrade_user
      post "/users/:user_id/downgrade", UserController, :downgrade_user
      post "/users/:user_id/add_admin", UserController, :add_admin
      post "/users/:user_id/revoke_admin", UserController, :revoke_admin
      post "/users/:user_id/make_superuser", UserController, :make_superuser
      post "/users/:user_id/revoke_superuser", UserController, :revoke_superuser
    end

  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:email_notifications, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: EmailNotificationsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
