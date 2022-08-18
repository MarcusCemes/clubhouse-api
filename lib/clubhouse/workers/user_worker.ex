defmodule Clubhouse.UserWorker do
  @moduledoc """
  Background worker for user-related tasks.
  """

  use Oban.Worker

  alias Clubhouse.Accounts.User
  alias Clubhouse.Repo
  alias Clubhouse.Discourse

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    case args do
      %{"action" => "sign_out", "id" => id} -> sign_out(id)
    end
  end

  defp sign_out(id) do
    user = Repo.get(User, id)
    Discourse.log_out(user)
    :ok
  end
end
