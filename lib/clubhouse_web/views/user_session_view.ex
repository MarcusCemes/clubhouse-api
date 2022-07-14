defmodule ClubhouseWeb.UserSessionView do
  use ClubhouseWeb, :view

  def accept_path(conn) do
    Routes.user_session_path(conn, :confirm, then: conn.query_params["then"])
  end
end
