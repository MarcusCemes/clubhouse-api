defmodule ClubhouseWeb.InfoView do
  use ClubhouseWeb, :view

  @contact_email "clubhouse@mastermovies.uk"
  @tos_last_update "28 April 2022"

  def contact_email() do
    @contact_email
  end

  def website_url() do
    Application.fetch_env!(:clubhouse, ClubhouseWeb.Endpoint)[:url][:host]
  end

  def forum_url(path) do
    forum_url() <> path
  end

  def forum_url() do
    Application.fetch_env!(:clubhouse, :services)[:forum_url]
  end

  def tos_last_update() do
    @tos_last_update
  end
end
