defmodule ClubhouseWeb.Router do
  use ClubhouseWeb, :router

  pipeline :browser do
    plug :fetch_session
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", ClubhouseWeb do
  #   pipe_through :browser
  # end

  scope "/auth", ClubhouseWeb do
    pipe_through :api

    post "/start", SessionController, :start
    post "/complete", SessionController, :complete
    get "/current-user", SessionController, :current_user
    post "/confirm-account", SessionController, :confirm_account
    get "/username-availability/:username", SessionController, :check_username
    post "/choose-username", SessionController, :choose_username
    post "/discourse/connect", DiscourseController, :connect
    post "/sign-out", SessionController, :sign_out
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ClubhouseWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
