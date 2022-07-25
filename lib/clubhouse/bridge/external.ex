defmodule Clubhouse.Bridge.External do
  @moduledoc """
  Communicates with the external bridge over the network.
  """

  @service "Clubhouse"

  defmodule BridgeError do
    defexception message: "The bridge is not reachable", plug_status: 503
  end

  def create_request(return_url) do
    payload = %{return_url: return_url, service: @service}
    response = make_request("/createRequest", payload)

    with {:ok, %{"key" => key}} <- response do
      {:ok, key}
    end
  end

  def fetch_attributes(key, auth_check) do
    payload = %{key: key, auth_check: auth_check}
    response = make_request("/fetchAttributes", payload)

    with {:ok, %{"attributes" => attrs}} <- response do
      {:ok, attrs}
    end
  end

  defp make_request(path, payload) do
    case Tesla.post(client(), path, payload) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:error, _} -> raise BridgeError
    end
  end

  defp client() do
    middleware = [
      {Tesla.Middleware.BaseUrl, bridge_url()},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [
         {"Authorization", "Bearer #{api_key()}"},
         {"Content-Type", "application/json"}
       ]},
      {Tesla.Middleware.Timeout, timeout: 5000}
    ]

    Tesla.client(middleware)
  end

  defp bridge_url(), do: Keyword.get(services(), :bridge_url)
  defp api_key(), do: Keyword.get(services(), :bridge_api_key)
  defp services(), do: Application.fetch_env!(:clubhouse, :services)
end
