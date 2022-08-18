defmodule Clubhouse.Discourse do
  @moduledoc """
  Provides an interface to the external Discourse application,
  such as executing admin API actions. If the forum is down,
  the functions make block for an extended period of time
  (several seconds).
  """

  import Clubhouse.Utility, only: [service_env: 1]

  @doc """
  Uses the Discourse Admin API to log out a user.
  """
  def log_out(user) do
    with {:id, discourse_id} <- get_external_id(user) do
      log_out_id(discourse_id)
      :ok
    end
  end

  defp get_external_id(user) do
    url = forum_host() <> "/users/by-external/#{user.uid}.json"
    response = Finch.build(:get, url) |> Finch.request(FinchClient)

    with {:ok, %Finch.Response{status: 200, body: body}} <- response,
         {:ok, payload} <- Jason.decode(body) do
      {:id, payload["user"]["id"]}
    end
  end

  defp log_out_id(discourse_id) do
    url = forum_host() <> "/admin/users/#{discourse_id}/log_out"
    Finch.build(:post, url, headers()) |> Finch.request(FinchClient)
  end

  defp headers do
    [
      {"Api-Username", "clubhouse"},
      {"Api-Key", service_env(:forum_api_key)}
    ]
  end

  defp forum_host, do: service_env(:forum_host)
end
