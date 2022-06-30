defmodule ClubhouseWeb.InfoControllerTest do
  use ClubhouseWeb.ConnCase

  test "GET /about", %{conn: conn} do
    conn = get(conn, "/about")

    assert conn |> html_response(200) |> sanitize() =~
             "Clubhouse is a student-run initiative that aims to create a dynamic community of students and EPFL members."
  end

  test "GET /frequently-asked-questions", %{conn: conn} do
    conn = get(conn, "/frequently-asked-questions")

    assert conn |> html_response(200) |> sanitize() =~ "Is there a mobile application?"
  end

  test "GET /code-of-conduct", %{conn: conn} do
    conn = get(conn, "/code-of-conduct")

    assert conn |> html_response(200) |> sanitize() =~
             "Please treat this discussion forum with the same respect you would a public park."
  end

  test "GET /privacy", %{conn: conn} do
    conn = get(conn, "/privacy")

    assert conn |> html_response(200) |> sanitize() =~
             "We collect information from you when you register on our site and gather data when you participate in the forum by reading, writing, and evaluating the content shared here."
  end

  test "GET /terms-of-service", %{conn: conn} do
    conn = get(conn, "/terms-of-service")

    assert conn |> html_response(200) |> sanitize() =~
             "you must agree to these terms with Clubhouse"
  end

  defp sanitize(html) do
    String.replace(html, "\n", " ")
  end
end
