defmodule ClubhouseWeb.PageControllerTest do
  use ClubhouseWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "An unofficial website for the EPFL community."
  end
end
