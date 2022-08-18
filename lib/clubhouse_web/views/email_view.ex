defmodule ClubhouseWeb.EmailView do
  use ClubhouseWeb, :view

  import Clubhouse.Utility, only: [service_env: 1]

  def url(:website), do: service_env(:website_url)
  def url(:code), do: service_env(:website_url) <> "/code-of-conduct"
  def url(:forum), do: service_env(:forum_url)
  def url(:static, path), do: service_env(:static_url) <> path

  def address(:appeal), do: service_env(:appeal_address)
end
