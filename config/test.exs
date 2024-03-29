import Config
import System, only: [get_env: 1, get_env: 2]

# Configure the application environment
config :clubhouse, env: :test

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :clubhouse, Clubhouse.Repo,
  username: "postgres",
  password: "postgres",
  hostname: get_env("DATABASE_HOST", "postgres"),
  database: "clubhouse_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :clubhouse, ClubhouseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "htRE82QBMvqvIl7w9QLeoTvbY3nFl+OOvHyDvu22rqSAf79XjVae2Jrdr651VSJ6",
  server: false

# In test we don't send emails.
config :clubhouse, Clubhouse.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Disable Oban during tests
config :clubhouse, Oban, testing: :inline

# Use the bridge mock
config :clubhouse, :services, mock_bridge: true
