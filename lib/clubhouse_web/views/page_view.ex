defmodule ClubhouseWeb.PageView do
  use ClubhouseWeb, :view

  @links [
    {"About", :about},
    {"FAQ", :frequently_asked_questions},
    {"Conduct", :code_of_conduct},
    {"Privacy", :privacy_policy},
    {"Terms", :terms_of_service}
  ]

  @forum_url "https://forum.clubhouse.test"

  def links() do
    @links
  end

  def forum_url() do
    @forum_url
  end
end
