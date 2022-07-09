defmodule ClubhouseWeb.EmailView do
  use ClubhouseWeb, :view

  alias ClubhouseWeb.Endpoint

  def website_url, do: Routes.page_url(Endpoint, :index)
  def code_of_conduct_url, do: Routes.info_url(Endpoint, :code_of_conduct)
  def forum_url, do: Keyword.get(env(), :forum_url)
  def appeal_address, do: Keyword.get(env(), :appeal_address)

  def static_url(path), do: Keyword.get(env(), :static_url) <> path

  defp env, do: Application.fetch_env!(:clubhouse, :services)
end
