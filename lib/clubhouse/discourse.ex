defmodule Clubhouse.Discourse do
  @moduledoc """
  Module to interact with the external Discourse application,
  such as executing admin API actions.
  """

  import Clubhouse.Utility, only: [service_env: 1]

  @doc """
  Uses the Discourse Admin API to log out a user.
  """
  def log_out(user) do
    client = new_client()

    case get_external_id(client, user) do
      {:id, discourse_id} ->
        log_out_id(client, discourse_id)
        :ok

      error ->
        {:error, error}
    end
  end

  defp get_external_id(client, user) do
    response = Tesla.get(client, "/users/by-external/#{user.uid}.json")

    with {:ok, %Tesla.Env{status: 200, body: body}} <- response do
      {:id, body["user"]["id"]}
    end
  end

  defp log_out_id(client, discourse_id) do
    Tesla.post(client, "/admin/users/#{discourse_id}/log_out", nil)
  end

  defp new_client() do
    middleware = [
      {Tesla.Middleware.BaseUrl, service_env(:forum_host)},
      {Tesla.Middleware.Headers,
       [
         {"Api-Username", "clubhouse"},
         {"Api-Key", service_env(:forum_api_key)}
       ]},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware)
  end
end
