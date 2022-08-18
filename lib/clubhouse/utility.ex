defmodule Clubhouse.Utility do
  @moduledoc """
  Generic utility functions that are not specific to a context.
  """

  @doc """
  Quickly fetch a configuration key from `config :clubhouse, :services`.
  """
  def service_env(key) do
    Application.fetch_env!(:clubhouse, :services) |> Keyword.get(key)
  end

  @doc """
  Appends a query string to a URL, which may already have
  an existing query string, with the appropriate.
  """
  def append_query_string(url, query) do
    url <> query_string_separator(url) <> query
  end

  defp query_string_separator(url) do
    if String.contains?(url, "?"), do: "&", else: "?"
  end
end
