defmodule Clubhouse.Bridge.External do
  @moduledoc """
  Communicates with the external bridge over the network.
  """

  import Clubhouse.Utility, only: [append_query_string: 2, service_env: 1]

  @service "Clubhouse"

  def create_request(return_url) do
    payload = %{return_url: return_url, service: @service}
    response = make_request("/createRequest", payload)

    with {:ok, %{"key" => key}} <- response do
      base = service_env(:tequila_url) <> "/requestauth"
      query = "requestkey=#{key}"
      {:ok, append_query_string(base, query)}
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
    request = Finch.build(:post, bridge_host() <> path, headers(), Jason.encode!(payload))
    response = Finch.request(request, FinchClient)

    with {:ok, %Finch.Response{status: 200, body: body}} <- response do
      {:ok, Jason.decode!(body)}
    else
      {:ok, %Finch.Response{status: 401}} -> {:error, :bridge}
      {:error, %Mint.TransportError{reason: :ehostunreach}} -> {:error, :bridge}
      {:error, %Mint.TransportError{reason: :econnrefused}} -> {:error, :bridge}
      _error -> {:error, :unknown}
    end
  end

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> service_env(:bridge_api_key)}
    ]
  end

  defp bridge_host, do: service_env(:bridge_host)
end
