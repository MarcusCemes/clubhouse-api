defmodule ClubhouseWeb.PageView do
  use ClubhouseWeb, :view

  @links [
    {"About", "/about"},
    {"FAQ", "/faq"},
    {"Conduct", "/code-of-conduct"},
    {"Privacy", "/privacy"},
    {"Terms", "/terms-of-service"}
  ]

  @forum_url "https://forum.clubhouse.test"

  def links() do
    @links
  end

  def forum_url() do
    @forum_url
  end
end
