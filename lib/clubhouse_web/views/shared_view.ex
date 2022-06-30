defmodule ClubhouseWeb.SharedView do
  use ClubhouseWeb, :view

  @footer_links [
    {"Home", :page_path, :index},
    {"Privacy", :info_path, :privacy_policy},
    {"FAQ", :info_path, :frequently_asked_questions},
    {"Terms", :info_path, :terms_of_service},
    {"Conduct", :info_path, :code_of_conduct}
  ]

  def footer_links() do
    @footer_links
  end
end
