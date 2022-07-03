defmodule Clubhouse.Bridge do
  @moduledoc """
  Interface for interaction with the Clubhouse Bridge.
  """

  def create_request(return_url) do
    bridge_impl().create_request(return_url)
  end

  def fetch_attributes(key, auth_check) do
    bridge_impl().fetch_attributes(key, auth_check)
  end

  defp bridge_impl() do
    with {:ok, config} <-
           Application.fetch_env(:clubhouse, :bridge),
         true <- Keyword.get(config, :mock) do
      Clubhouse.Bridge.Mock
    else
      _ -> Clubhouse.Bridge.External
    end
  end
end
