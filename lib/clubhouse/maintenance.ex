defmodule Clubhouse.Maintenance do
  @moduledoc """
  Perform upkeep functions, usually executed periodically
  by the scheduler module.
  """

  import Ecto.Query

  alias Clubhouse.Accounts.UserToken
  alias Clubhouse.Repo

  import UserToken, only: [session_validity_in_days: 0]
  require Logger

  @doc """
  Deletes old session tokens from the database.
  """
  def delete_old_sessions() do
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
