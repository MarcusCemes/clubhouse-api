defmodule Clubhouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Clubhouse.Repo,
      # Start the Telemetry supervisor
      ClubhouseWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Clubhouse.PubSub},
      # Start the Endpoint (http/https)
      ClubhouseWeb.Endpoint,
      # Background jobs
      Clubhouse.Scheduler,
      # Global state for development and tests
      Clubhouse.DevHelper
      # Start a worker by calling: Clubhouse.Worker.start_link(arg)
      # {Clubhouse.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Clubhouse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClubhouseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
