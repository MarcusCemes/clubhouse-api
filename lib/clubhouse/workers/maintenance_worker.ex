defmodule Clubhouse.MaintenanceWorker do
  @moduledoc """
  Background worker to perform periodic maintenance.
  """

  require Logger

  use Oban.Worker

  alias Clubhouse.Accounts.UserToken
  alias Clubhouse.Repo

  import Ecto.Query
  import UserToken, only: [session_validity_in_days: 0]

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    delete_old_sessions()
  end

  defp delete_old_sessions() do
    {count, _} = Repo.delete_all(old_sessions_query())
    log_info("Deleted #{count} user session tokens")
  end

  defp old_sessions_query() do
    from ut in UserToken,
      where: ut.inserted_at <= ago(^session_validity_in_days(), "day")
  end

  defp log_info(text) do
    Logger.info("[MAINTENANCE] " <> text)
  end
end
