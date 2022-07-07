defmodule Clubhouse.Bridge do
  @moduledoc """
  Interface for interaction with the Clubhouse Bridge.
  """

  @spec create_request(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def create_request(return_url) do
    bridge_impl().create_request(return_url)
  end

  @spec fetch_attributes(String.t(), String.t()) ::
          {:ok, %{String.t() => String.t()}} | {:error, atom()}
  def fetch_attributes(key, auth_check) do
    bridge_impl().fetch_attributes(key, auth_check)
  end

  @doc """
  Map Tequila attributes to an atom-indexed object with attributes
  used by the User struct.
  """
  def parse_attrs(attrs) do
    [
      email: "email",
      first_name: "firstname",
      last_name: "name",
      sciper: "uniqueid"
    ]
    |> Enum.map(fn {key, value} -> {key, attrs[value]} end)
    |> Map.new()
  end

  defp bridge_impl() do
    if mocked_bridge?() do
      Clubhouse.Bridge.Mock
    else
      Clubhouse.Bridge.External
    end
  end

  def mocked_bridge?() do
    case Application.fetch_env(:clubhouse, :bridge) do
      {:ok, config} -> Keyword.get(config, :mock) == true
      _ -> false
    end
  end
end
