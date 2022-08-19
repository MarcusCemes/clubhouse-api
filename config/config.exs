# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :clubhouse,
  ecto_repos: [Clubhouse.Repo]

# Configures the endpoint
config :clubhouse, ClubhouseWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ClubhouseWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Clubhouse.PubSub,
  live_view: [signing_salt: "vYQeCiSB"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :clubhouse, Clubhouse.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Service configuration
config :clubhouse, :services,
  website_url: "http://clubhouse.test",
  bridge_host: "http://bridge",
  bridge_api_key: "clubhouse-dev",
  forum_host: "http://discourse",
  discourse_secret: "clubhouse-dev",
  tequila_url: "https://tequila.epfl.ch/cgi-bin/tequila",
  mailer_sender: "clubhouse@clubhouse.test",
  static_url: "https://static.clubhouse.test",
  appeal_address: "human@clubhouse.test"

# Job processing
config :clubhouse, Oban,
  repo: Clubhouse.Repo,
  queues: [default: 10],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       # Every day at 03:00
       {"0 3 * * *", Clubhouse.MaintenanceWorker}
     ]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
