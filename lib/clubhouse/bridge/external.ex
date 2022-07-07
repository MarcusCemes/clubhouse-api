defmodule Clubhouse.Bridge.External do
  @moduledoc """
  Communicates with the external bridge over the network.
  """

  @service "Clubhouse"

  def create_request(return_url) do
    payload = %{return_url: return_url, service: @service}
    %{"key" => key} = make_request("/createRequest", payload)
    {:ok, key}
  end

  def fetch_attributes(key, auth_check) do
    payload = %{key: key, auth_check: auth_check}
    %{"attributes" => attrs} = make_request("/fetchAttributes", payload)
    {:ok, attrs}
  end

  defp make_request(path, payload) do
    {:ok, %Tesla.Env{status: 200, body: body}} = Tesla.post(client(), path, payload)
    body
  end

  defp client() do
    middleware = [
      {Tesla.Middleware.BaseUrl, bridge_url()},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [
         {"Authorization", "Bearer #{api_key()}"},
         {"Content-Type", "application/json"}
       ]}
    ]

    Tesla.client(middleware)
  end

  defp bridge_url(), do: Keyword.get(services(), :bridge_url)
  defp api_key(), do: Keyword.get(services(), :bridge_api_key)
  defp services(), do: Application.fetch_env!(:clubhouse, :services)
end
