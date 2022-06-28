defmodule ClubhouseWeb.PageController do
  use ClubhouseWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
