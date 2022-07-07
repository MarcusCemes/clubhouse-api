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

  def sign_in_out_link(conn, action) do
    return_path = Phoenix.Controller.current_path(conn)
    Routes.user_session_path(conn, action, return_path: return_path)
  end

  def flash_messages(conn) do
    [:error, :warning, :info, :success]
    |> Enum.map(fn type -> {type, get_flash(conn, type)} end)
  end

  def toast_icon_name(type) do
    case type do
      :error -> "x-circle"
      :warning -> "exclamation"
      :info -> "information-circle"
      :success -> "check-circle"
      _ -> nil
    end
  end

  def toast_colour(type) do
    case type do
      :error -> "bg-red-50 text-red-500 border-red-500"
      :warning -> "bg-orange-50 text-orange-500 border-orange-500"
      :info -> "bg-blue-50 text-blue-500 border-blue-500"
      :success -> "bg-green-50 text-green-500 border-green-500"
      _ -> ""
    end
  end
end
